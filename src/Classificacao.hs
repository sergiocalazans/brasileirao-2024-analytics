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
    -- * Disciplina e sorteio
  , RegistroCartoes (..)
  , StatusDesempate (..)
  , totalCartoesVermelhos
  , totalCartoesAmarelos
  , statusDesempate
  , empateDependeDeSorteio
  , classificacaoComDisciplina
  , criterioDecisivoComDisciplina
    -- * Tabela e critérios de desempate
  , criterios
  , compararLinhas
  , criterioDecisivo
  , criterioDecisivoCampeonato
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
-- Disciplina e sorteio
-- ---------------------------------------------------------------------

-- | Dados disciplinares complementares de um clube (em base separada,
--   sem alterar o CSV de partidas).
data RegistroCartoes = RegistroCartoes
  { clubeDisciplina :: Time
  , cartoesVermelhos :: Int
  , cartoesAmarelos  :: Int
  } deriving (Show, Eq)

-- | Estado explícito de um desempate: resolvido por um critério ou
--   pendente de sorteio quando todos os critérios objetivos empatam.
data StatusDesempate
  = ResolvidoPor String
  | EmpateParaSorteio
  deriving (Show, Eq)

-- | Soma de cartões vermelhos de um time (0 quando não há dados).
totalCartoesVermelhos :: [RegistroCartoes] -> Time -> Int
totalCartoesVermelhos regs t =
  foldr (\r acc -> acc + cartoesVermelhos r) 0
    (filter ((== t) . clubeDisciplina) regs)

-- | Soma de cartões amarelos de um time (0 quando não há dados).
totalCartoesAmarelos :: [RegistroCartoes] -> Time -> Int
totalCartoesAmarelos regs t =
  foldr (\r acc -> acc + cartoesAmarelos r) 0
    (filter ((== t) . clubeDisciplina) regs)

-- | Critérios objetivos na ordem do regulamento adaptada com disciplina:
--   pontos, vitórias, saldo de gols, gols marcados, confronto direto
--   (apenas entre 2 clubes empatados em pontos com ida e volta), menores
--   cartões vermelhos e menores cartões amarelos.
criteriosObjetivosComDisciplina
  :: [Partida] -> [Linha] -> [RegistroCartoes] -> [(String, Linha -> Linha -> Ordering)]
criteriosObjetivosComDisciplina partidas tabela regs =
  [ ("pontos",                      comparing (Down . pontosLinha))
  , ("vitorias",                    comparing (Down . vitorias))
  , ("saldo de gols",               comparing (Down . saldo))
  , ("gols marcados",               comparing (Down . golsPro))
  , ("confronto direto",            confrontoDireto partidas tabela)
  , ("menores cartoes vermelhos",   comparing (totalCartoesVermelhos regs . time))
  , ("menores cartoes amarelos",    comparing (totalCartoesAmarelos regs . time))
  ]

-- | Indica se duas linhas empatam em todos os critérios objetivos,
--   exigindo sorteio sem inventar resultado.
statusDesempate :: [Partida] -> [RegistroCartoes] -> Linha -> Linha -> StatusDesempate
statusDesempate partidas regs a b =
  maybe EmpateParaSorteio ResolvidoPor
    (find (\(_, comp) -> comp a b /= EQ) (criteriosObjetivosComDisciplina partidas tabela regs)
      >>= \(nome, _) -> Just nome)
  where
    tabela = map (linhaDoTime partidas) (times partidas)

-- | Verdadeiro quando o empate não é decidido por nenhum critério objetivo
--   e depende de sorteio.
empateDependeDeSorteio :: [Partida] -> [RegistroCartoes] -> Linha -> Linha -> Bool
empateDependeDeSorteio partidas regs a b =
  statusDesempate partidas regs a b == EmpateParaSorteio

-- | Explica o critério objetivo decisivo; devolve Nothing quando o empate
--   permanece aberto para sorteio.
criterioDecisivoComDisciplina
  :: [Partida] -> [RegistroCartoes] -> Linha -> Linha -> Maybe String
criterioDecisivoComDisciplina partidas regs a b =
  case statusDesempate partidas regs a b of
    ResolvidoPor nome -> Just nome
    EmpateParaSorteio -> Nothing

-- | Ordena com os critérios objetivos e, quando todos empatam (sorteio),
--   mantém ordenação determinística por nome do clube sem inventar placar.
classificacaoComDisciplina :: [Partida] -> [RegistroCartoes] -> [Linha]
classificacaoComDisciplina partidas regs =
  sortBy comparar tabela
  where
    tabela = map (linhaDoTime partidas) (times partidas)
    listaCriterios =
      criteriosObjetivosComDisciplina partidas tabela regs
        ++ [("sorteio (ordem alfabetica)", comparing time)]
    comparar a b = foldr (\(_, comp) resto -> comp a b <> resto) EQ listaCriterios

-- ---------------------------------------------------------------------
-- Tabela e critérios de desempate
-- ---------------------------------------------------------------------

-- | Critérios de classificação do Brasileirão, em ordem de prioridade.
--   Cada um tem um nome (usado para explicar desempates) e uma comparação.
--   Down inverte a ordem: quem tem MAIS pontos, vitórias etc. fica acima.
--   Estes criterios comparam linhas isoladas. O confronto direto exige
--   as partidas e é acrescentado por criteriosDoCampeonato.
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
--   seguintes nem chegam a ser avaliados.
compararLinhas :: Linha -> Linha -> Ordering
compararLinhas a b = foldr (\(_, compara) resto -> compara a b <> resto) EQ criterios

-- | Nome do primeiro critério que separa as duas linhas (Nothing se forem
--   idênticas). Mostra, na tabela e nos testes, qual critério decidiu.
criterioDecisivo :: Linha -> Linha -> Maybe String
criterioDecisivo a b = fst <$> find (\(_, compara) -> compara a b /= EQ) criterios

-- | Tabela completa: uma linha por time, ordenada pelos critérios com sortBy.
classificacao :: [Partida] -> [Linha]
classificacao partidas =
  sortBy comparar tabela
  where
    tabela = map (linhaDoTime partidas) (times partidas)
    comparar a b = foldr (\(_, criterio) resto -> criterio a b <> resto) EQ
      (criteriosDoCampeonato partidas tabela)

-- | Regra do confronto direto: só se aplica a exatamente dois clubes
--   empatados em pontos, com ida e volta disponíveis.
confrontoDireto :: [Partida] -> [Linha] -> Linha -> Linha -> Ordering
confrontoDireto partidas tabela a b
  | length (filter ((== pontosLinha a) . pontosLinha) tabela) /= 2 = EQ
  | length ida /= 1 || length volta /= 1 = EQ
  | otherwise = comparing (Down . saldo . linhaDoTime (ida ++ volta) . time) a b
  where
    ida   = filter (\p -> mandante p == time a && visitante p == time b) partidas
    volta = filter (\p -> mandante p == time b && visitante p == time a) partidas

-- | Acrescenta o confronto direto antes do desempate alfabetico.
--   O regulamento de 2024 só o aplica a dois times empatados em pontos,
--   considerando o placar agregado dos jogos de ida e volta.
criteriosDoCampeonato :: [Partida] -> [Linha] -> [(String, Linha -> Linha -> Ordering)]
criteriosDoCampeonato partidas tabela =
  take 4 criterios ++ [("confronto direto", confrontoDireto partidas tabela)] ++ drop 4 criterios

-- | Explica o desempate usando o mesmo contexto da classificacao.
criterioDecisivoCampeonato :: [Partida] -> Linha -> Linha -> Maybe String
criterioDecisivoCampeonato partidas a b =
  fst <$> find (\(_, compara) -> compara a b /= EQ) (criteriosDoCampeonato partidas tabela)
  where
    tabela = map (linhaDoTime partidas) (times partidas)

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