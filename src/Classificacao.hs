{-
  Módulo: Classificacao (Camada 2)
  Descrição: Calcula a classificação, pontuação, saldo de gols
             e estatísticas utilizando funções de ordem superior.

  Regras desta camada:
    * nenhuma recursão explícita: só map, filter, dobras (foldr), sortBy
      e composição com (.);
    * só funções totais: nada de head, maximum ou foldr1, que quebram com
      o campeonato vazio. Quando pode não haver resposta, o tipo é Maybe.
-}
module Classificacao
  ( -- * Pontuação de cada time
    pontos
  , linhaVazia
  , linhaDoTime
  , pontosLinha
  , saldo
  , aproveitamento
    -- * Tabela e critérios de desempate
  , criterios
  , compararLinhas
  , criterioDecisivo
  , classificacao
  , empatesEmPontos
    -- * Estatísticas do campeonato
  , ateRodada
  , ultimaRodada
  , golsDaPartida
  , diferencaGols
  , totalDeGols
  , maiorGoleada
  , mediaGols
  ) where

import Data.List (find, sortBy)
import Data.Ord (Down (..), comparing)

import Tipos

-- ---------------------------------------------------------------------
-- Pontuação de cada time
-- ---------------------------------------------------------------------

-- | Pontos de um resultado: 3 pela vitória, 1 pelo empate, 0 pela derrota.
pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

-- | Linha zerada de um time: o valor inicial da dobra em 'linhaDoTime'.
linhaVazia :: Time -> Linha
linhaVazia t = Linha
  { time = t, jogos = 0, vitorias = 0, empates = 0
  , derrotas = 0, golsPro = 0, golsContra = 0 }

-- | Linha da tabela de um time: filtra as partidas dele e acumula uma a
--   uma com foldr, a partir da linha zerada.
linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime partidas t =
  foldr (somarPartida t) (linhaVazia t) (filter (participou t) partidas)

-- | Acrescenta à linha o jogo, o resultado e os gols de uma partida do time.
somarPartida :: Time -> Partida -> Linha -> Linha
somarPartida t p l = l
  { jogos      = jogos l + 1
  , vitorias   = vitorias l + contar Vitoria
  , empates    = empates l + contar Empate
  , derrotas   = derrotas l + contar Derrota
  , golsPro    = golsPro l + golsMarcados t p
  , golsContra = golsContra l + golsSofridos t p
  }
  where
    -- 1 se a partida terminou com o resultado r para o time; 0 caso contrário
    contar r = if resultadoPara t p == Just r then 1 else 0

-- | Pontos ganhos. Usa 'pontos', então mudar a regra (ex.: 2 pontos por
--   vitória) exige alterar um único lugar.
pontosLinha :: Linha -> Int
pontosLinha l =
  pontos Vitoria * vitorias l + pontos Empate * empates l + pontos Derrota * derrotas l

-- | Saldo de gols: gols pró menos gols contra.
saldo :: Linha -> Int
saldo l = golsPro l - golsContra l

-- | Percentual (0 a 100) dos pontos disputados que o time conquistou;
--   0 se o time não jogou. fromIntegral converte os Int em Double antes
--   da divisão com (/), que exige um tipo fracionário.
aproveitamento :: Linha -> Double
aproveitamento l
  | jogos l == 0 = 0
  | otherwise    = 100 * fromIntegral (pontosLinha l) / fromIntegral disputados
  where
    disputados = pontos Vitoria * jogos l

-- ---------------------------------------------------------------------
-- Tabela e critérios de desempate
-- ---------------------------------------------------------------------

-- | Critérios de classificação do Brasileirão, em ordem de prioridade.
--   Cada um tem um nome (usado para explicar desempates) e uma comparação.
--   Down inverte a ordem: quem tem MAIS pontos, vitórias etc. fica acima.
--   Confronto direto, cartões e sorteio não existem nos dados; a ordem
--   alfabética ocupa o lugar do sorteio para a tabela ser determinística.
criterios :: [(String, Linha -> Linha -> Ordering)]
criterios =
  [ ("pontos",           comparing (Down . pontosLinha))
  , ("vitorias",         comparing (Down . vitorias))
  , ("saldo de gols",    comparing (Down . saldo))
  , ("gols marcados",    comparing (Down . golsPro))
  , ("ordem alfabetica", comparing time)
  ]

-- | Comparação completa: aplica os critérios em ordem e junta os resultados
--   com <>. Ordering é um Monoid em que LT <> _ = LT, GT <> _ = GT e
--   EQ <> y = y: o primeiro critério que diferencia os times decide, e os
--   seguintes nem chegam a ser avaliados. O resultado é o mesmo de escrever
--
--   >  comparing (Down . pontosLinha) <> comparing (Down . vitorias)
--   >    <> comparing (Down . saldo) <> comparing (Down . golsPro)
--   >    <> comparing time
--
--   mas com os critérios numa lista só, também usada por 'criterioDecisivo'.
compararLinhas :: Linha -> Linha -> Ordering
compararLinhas a b = foldr (\(_, compara) resto -> compara a b <> resto) EQ criterios

-- | Nome do primeiro critério que separa as duas linhas (Nothing se forem
--   idênticas). Mostra, na tabela e nos testes, qual critério decidiu.
criterioDecisivo :: Linha -> Linha -> Maybe String
criterioDecisivo a b = fst <$> find (\(_, compara) -> compara a b /= EQ) criterios

-- | Tabela completa: uma linha por time, ordenada pelos critérios com sortBy.
classificacao :: [Partida] -> [Linha]
classificacao partidas =
  sortBy compararLinhas (map (linhaDoTime partidas) (times partidas))

-- | Pares de times vizinhos na tabela que somam os mesmos pontos.
--   zip com drop 1 forma os pares sem usar tail (que quebra na lista vazia).
empatesEmPontos :: [Linha] -> [(Linha, Linha)]
empatesEmPontos tabela = filter mesmosPontos (zip tabela (drop 1 tabela))
  where
    mesmosPontos (a, b) = pontosLinha a == pontosLinha b

-- ---------------------------------------------------------------------
-- Estatísticas do campeonato
-- ---------------------------------------------------------------------

-- | Só as partidas disputadas até a rodada informada (inclusive).
ateRodada :: Int -> [Partida] -> [Partida]
ateRodada n = filter ((<= n) . rodada)

-- | Número da última rodada (0 se não houver partidas).
ultimaRodada :: [Partida] -> Int
ultimaRodada = foldr (max . rodada) 0

-- | Total de gols de uma partida.
golsDaPartida :: Partida -> Int
golsDaPartida p = golsMandante p + golsVisitante p

-- | Diferença de gols entre os dois times (nunca negativa).
diferencaGols :: Partida -> Int
diferencaGols p = abs (golsMandante p - golsVisitante p)

-- | Total de gols de uma lista de partidas.
totalDeGols :: [Partida] -> Int
totalDeGols = sum . map golsDaPartida

-- | Partida com a maior diferença de gols; Nothing para a lista vazia.
--   A dobra começa em Nothing, por isso não precisa de maximumBy nem de
--   foldr1 (que quebram com a lista vazia). Se houver empate na diferença,
--   fica a partida que aparece primeiro na lista.
maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada = foldr escolher Nothing
  where
    escolher p Nothing = Just p
    escolher p (Just atual)
      | diferencaGols p >= diferencaGols atual = Just p
      | otherwise                              = Just atual

-- | Média de gols por partida; Nothing para a lista vazia (sem divisão por zero).
mediaGols :: [Partida] -> Maybe Double
mediaGols [] = Nothing
mediaGols partidas =
  Just (fromIntegral (totalDeGols partidas) / fromIntegral (length partidas))
