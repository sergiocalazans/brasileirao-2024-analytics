{-
  Módulo: Main
  Descrição: Integra as três camadas do sistema e executa
             a exibição das tabelas, estatísticas e erros.

  main é a única função com IO: escolhe de onde vem o texto do campeonato
  (o próprio código ou, opcionalmente, um arquivo) e imprime o relatório.
  O relatório inteiro é montado por funções puras, testáveis sem IO.

  Uso (na raiz do projeto):
      runghc -isrc src/Main.hs                  dados de src/Dados.hs
      runghc -isrc src/Main.hs data/teste.txt   dados lidos de um arquivo
-}
module Main (main) where

import Control.Exception (IOException, evaluate, try)
import Data.List (intercalate)
import Data.Maybe (fromMaybe, mapMaybe)
import System.Environment (getArgs)

import Classificacao
import Dados
import Leitura
import Tipos

-- | Obtém os dados e imprime a demonstração das três camadas.
main :: IO ()
main = do
  argumentos <- getArgs
  case argumentos of
    [] -> putStr (demonstracao "Dados.hs (campeonato embutido no codigo)" dadosCampeonato)
    arquivo : _ -> do
      -- try devolve Left se o arquivo não puder ser lido (não existe, por
      -- exemplo); evaluate força a leitura completa ainda dentro do try.
      leitura <- try $ do
        texto <- readFile arquivo
        _ <- evaluate (length texto)
        return texto
      putStr (either falhaNaLeitura (demonstracao ("arquivo " ++ arquivo)) leitura)

-- | Mensagem para quando o arquivo informado não pode ser lido.
falhaNaLeitura :: IOException -> String
falhaNaLeitura erro = "Nao foi possivel ler o arquivo: " ++ show erro ++ "\n"

-- | Relatório completo, na ordem pedida: as camadas sobre o campeonato,
--   o campeonato vazio e o tratamento de uma entrada com erros.
demonstracao :: String -> String -> String
demonstracao origem texto = concat
  [ titulo "PjBL2 - Tabela de Classificacao de Campeonato"
  , "Fonte dos dados: " ++ origem ++ "\n\n"
  , case lerCampeonato texto of
      Right []       -> secao "Os dados informados nao tem partidas" ["(nada a classificar)"]
      Right partidas -> secoesDoCampeonato partidas
      Left _         -> secaoDeErros "Os dados informados tem erros" texto
  , secaoCampeonatoVazio
  , secaoDeErros "Camada 3 - Tratamento de uma entrada com erros" dadosComErros
  ]

-- | Camadas 1 e 2 sobre um campeonato lido sem erros: times e campanhas,
--   tabela final, tabela numa rodada intermediária e estatísticas.
secoesDoCampeonato :: [Partida] -> String
secoesDoCampeonato partidas = concat
  [ secao "Camada 1 - Times e campanhas (times, resultadoPara)" $
      [ "Times (" ++ show (length nomes) ++ "): " ++ intercalate ", " nomes
      , "Partidas: " ++ show (length partidas) ++ " em " ++ show (ultimaRodada partidas) ++ " rodadas"
      , "Resultados de cada time, rodada a rodada:"
      ] ++ map campanha nomes
  , secao "Camada 2 - Classificacao final" (tabelaComDesempates (classificacao partidas))
  , secao ("Camada 2 - Classificacao apos a rodada " ++ show meio)
      (tabelaComDesempates (classificacao (ateRodada meio partidas)))
  , secao "Camada 2 - Estatisticas" (estatisticas partidas)
  ]
  where
    nomes = times partidas
    meio  = max 1 ((ultimaRodada partidas + 1) `div` 2)
    largura = foldr (max . length) 0 nomes
    campanha t = "  " ++ alinharEsquerda largura t ++ "  "
                   ++ unwords (map show (mapMaybe (resultadoPara t) partidas))

-- | Tabela formatada seguida da explicação de cada empate em pontos.
tabelaComDesempates :: [Linha] -> [String]
tabelaComDesempates tabela =
  lines (tabelaFormatada tabela) ++ map explicarDesempate (empatesEmPontos tabela)

-- | Explica qual critério separou dois times com os mesmos pontos.
explicarDesempate :: (Linha, Linha) -> String
explicarDesempate (acima, abaixo) =
  "* " ++ time acima ++ " fica a frente de " ++ time abaixo
    ++ " (ambos com " ++ show (pontosLinha acima) ++ " pontos): desempate por "
    ++ fromMaybe "nenhum criterio" (criterioDecisivo acima abaixo)

-- | Estatísticas da Camada 2. Funcionam também sem partidas, pois
--   maiorGoleada e mediaGols devolvem Maybe.
estatisticas :: [Partida] -> [String]
estatisticas partidas =
  [ "Partidas disputadas: " ++ show (length partidas)
  , "Gols marcados:       " ++ show (totalDeGols partidas)
  , "Media de gols:       "
      ++ maybe "indisponivel (nenhuma partida)" ((++ " por partida") . formatarDecimal) (mediaGols partidas)
  , "Maior goleada:       "
      ++ maybe "nenhuma (nenhuma partida)" formatarPartida (maiorGoleada partidas)
  ]

-- | Robustez: um texto só com comentários vira um campeonato vazio e
--   todas as funções continuam respondendo, sem exceção.
secaoCampeonatoVazio :: String
secaoCampeonatoVazio = secao "Robustez - Campeonato vazio (so comentarios, nenhuma partida)" $
  case lerCampeonato dadosSemPartidas of
    Left erro      -> [mensagemErro erro]
    Right partidas -> lines (tabelaFormatada (classificacao partidas)) ++ estatisticas partidas

-- | Camada 3: o primeiro erro (lerCampeonato) e o relatório completo (todosOsErros).
secaoDeErros :: String -> String -> String
secaoDeErros nome texto = secao nome $
  [ "lerCampeonato para no primeiro erro:"
  , "  " ++ either mensagemErro (const "nenhum erro encontrado") (lerCampeonato texto)
  , "todosOsErros lista todos os problemas (" ++ show (length erros) ++ "):"
  ] ++ map (("  - " ++) . mensagemErro) erros
  where
    erros = todosOsErros texto

-- | Seção do relatório: título sublinhado e as linhas do corpo recuadas.
secao :: String -> [String] -> String
secao nome corpo = unlines ([nome, replicate (length nome) '-'] ++ map ("  " ++) corpo) ++ "\n"

-- | Título principal do relatório, entre duas linhas de "=".
titulo :: String -> String
titulo nome = unlines [borda, nome, borda]
  where
    borda = replicate (length nome) '='
