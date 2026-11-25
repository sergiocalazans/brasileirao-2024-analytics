{-
  Módulo: Testes
  Descrição: Executa os testes das três camadas, verificando
             os resultados esperados e o tratamento de erros.

  Cada teste compara o valor obtido com o esperado, conferido à mão.
  Executar na raiz do projeto:   runghc -isrc tests/Testes.hs
  O programa termina com código de saída 1 se algum teste falhar.
-}
module Main (main) where

import Data.List (find)
import Data.Maybe (fromMaybe)
import System.Exit (exitFailure, exitSuccess)

import Classificacao
import Dados
import Leitura
import Tipos

-- ---------------------------------------------------------------------
-- Auxiliares
-- ---------------------------------------------------------------------

-- | Compara o obtido com o esperado, imprime OK ou FALHOU e devolve se
--   passou. É a função sugerida no enunciado, mostrando também o esperado.
testar :: (Eq a, Show a) => String -> a -> a -> IO Bool
testar nome obtido esperado
  | obtido == esperado = do
      putStrLn ("OK      " ++ nome)
      return True
  | otherwise = do
      putStrLn ("FALHOU  " ++ nome)
      putStrLn ("          obtido:   " ++ show obtido)
      putStrLn ("          esperado: " ++ show esperado)
      return False

-- | Executa um grupo de testes depois de imprimir o seu título.
grupo :: String -> [IO Bool] -> IO [Bool]
grupo nome testes = do
  putStrLn ("\n== " ++ nome ++ " ==")
  sequence testes

-- | Roda os testes das três camadas e mostra o resumo.
main :: IO ()
main = do
  resultados <- concat <$> sequence
    [ grupo "Camada 1 - Tipos e consultas basicas" testesCamada1
    , grupo "Camada 2 - Classificacao e estatisticas" testesCamada2
    , grupo "Camada 3 - Leitura, validacao e formatacao" testesCamada3
    ]
  let total  = length resultados
      falhas = length (filter not resultados)
  putStrLn ("\n" ++ show (total - falhas) ++ " de " ++ show total ++ " testes passaram.")
  if falhas == 0 then exitSuccess else exitFailure

-- ---------------------------------------------------------------------
-- Valores esperados, conferidos à mão
-- ---------------------------------------------------------------------

-- | O campeonato de Dados.hs escrito diretamente como partidas.
partidasDeTeste :: [Partida]
partidasDeTeste =
  [ Partida 1 "Botafogo" 1 2 "Palmeiras"
  , Partida 1 "Fortaleza" 0 1 "Internacional"
  , Partida 1 "Flamengo" 0 0 "Cruzeiro"
  , Partida 2 "Internacional" 1 3 "Botafogo"
  , Partida 2 "Palmeiras" 4 0 "Cruzeiro"
  , Partida 2 "Fortaleza" 2 2 "Flamengo"
  , Partida 3 "Botafogo" 2 1 "Cruzeiro"
  , Partida 3 "Internacional" 3 3 "Flamengo"
  , Partida 3 "Palmeiras" 0 1 "Fortaleza"
  , Partida 4 "Flamengo" 1 1 "Botafogo"
  , Partida 4 "Cruzeiro" 1 2 "Fortaleza"
  , Partida 4 "Internacional" 1 2 "Palmeiras"
  , Partida 5 "Botafogo" 3 0 "Fortaleza"
  , Partida 5 "Flamengo" 2 0 "Palmeiras"
  , Partida 5 "Cruzeiro" 3 1 "Internacional"
  ]

-- | Classificação final, conferida à mão.
--   Campos: time, jogos, vitorias, empates, derrotas, golsPro, golsContra.
tabelaFinal :: [Linha]
tabelaFinal =
  [ Linha "Botafogo"      5 3 1 1 10  5   -- 10 pts, saldo +5
  , Linha "Palmeiras"     5 3 0 2  8  5   --  9 pts, saldo +3
  , Linha "Fortaleza"     5 2 1 2  5  7   --  7 pts, 2 vitorias, saldo -2
  , Linha "Flamengo"      5 1 4 0  8  6   --  7 pts, 1 vitoria,  saldo +2
  , Linha "Internacional" 5 1 1 3  7 11   --  4 pts, saldo -4, 7 gols
  , Linha "Cruzeiro"      5 1 1 3  5  9   --  4 pts, saldo -4, 5 gols
  ]

-- | Classificação após a 3ª rodada, conferida à mão.
tabelaRodada3 :: [Linha]
tabelaRodada3 =
  [ Linha "Palmeiras"     3 2 0 1 6 2   -- 6 pts, saldo +4
  , Linha "Botafogo"      3 2 0 1 6 4   -- 6 pts, saldo +2
  , Linha "Fortaleza"     3 1 1 1 3 3   -- 4 pts, saldo  0
  , Linha "Internacional" 3 1 1 1 5 6   -- 4 pts, saldo -1
  , Linha "Flamengo"      3 0 3 0 5 5   -- 3 pts
  , Linha "Cruzeiro"      3 0 1 2 1 6   -- 1 pt
  ]

-- | Os 7 erros da entrada com erros de Dados.hs, na ordem das linhas.
errosEsperados :: [Erro]
errosEsperados =
  [ NumeroInvalido 3 "dois"
  , CamposInvalidos 4 4
  , PlacarNegativo 5
  , MesmoTime 6 "Cruzeiro"
  , RodadaInvalida 7 0
  , TimeVazio 8
  , TimeRepetidoNaRodada 2 "Flamengo"
  ]

-- | Jogo em que o visitante venceu: Botafogo 1 x 2 Palmeiras.
jogoFora :: Partida
jogoFora = Partida 1 "Botafogo" 1 2 "Palmeiras"

-- | O empate em 0 x 0 do campeonato de teste.
jogoSemGols :: Partida
jogoSemGols = Partida 1 "Flamengo" 0 0 "Cruzeiro"

-- | Linha de um time numa tabela (linha zerada se ele não estiver nela).
linhaDe :: Time -> [Linha] -> Linha
linhaDe t tabela = fromMaybe (linhaVazia t) (find ((== t) . time) tabela)

-- | Posição (1, 2, ...) de um time na classificação final calculada.
posicaoFinal :: Time -> Int
posicaoFinal t = 1 + length (takeWhile ((/= t) . time) (classificacao partidasDeTeste))

-- | Verdadeiro se, na rodada r, cada time aparece em uma única partida.
rodadaSemRepeticao :: Int -> Bool
rodadaSemRepeticao r = 2 * length daRodada == length (times daRodada)
  where
    daRodada = filter ((== r) . rodada) partidasDeTeste

-- ---------------------------------------------------------------------
-- Camada 1: tipos e consultas básicas
-- ---------------------------------------------------------------------

testesCamada1 :: [IO Bool]
testesCamada1 =
  [ testar "resultadoPara o mandante que perdeu em casa (1 x 2)"
      (resultadoPara "Botafogo" jogoFora) (Just Derrota)
  , testar "resultadoPara o visitante que venceu fora (2 x 1)"
      (resultadoPara "Palmeiras" jogoFora) (Just Vitoria)
  , testar "resultadoPara um time que nao jogou a partida e Nothing"
      (resultadoPara "Flamengo" jogoFora) Nothing
  , testar "resultadoPara no 0 x 0 e Empate para os dois times"
      (map (`resultadoPara` jogoSemGols) ["Flamengo", "Cruzeiro"]) [Just Empate, Just Empate]
  , testar "participou: mandante e visitante sim, outro time nao"
      (map (`participou` jogoFora) ["Botafogo", "Palmeiras", "Flamengo"]) [True, True, False]
  , testar "golsMarcados e golsSofridos do ponto de vista do visitante"
      (golsMarcados "Palmeiras" jogoFora, golsSofridos "Palmeiras" jogoFora) (2, 1)
  , testar "golsMarcados de quem nao jogou e 0 (neutro na soma)"
      (golsMarcados "Flamengo" jogoFora) 0
  , testar "times do campeonato de teste: sem repeticao, em ordem alfabetica"
      (times partidasDeTeste)
      ["Botafogo", "Cruzeiro", "Flamengo", "Fortaleza", "Internacional", "Palmeiras"]
  , testar "times de um campeonato sem partidas e []"
      (times []) []
    -- requisitos mínimos do campeonato de teste
  , testar "campeonato de teste: 6 times, 5 rodadas e 15 partidas"
      (length (times partidasDeTeste), ultimaRodada partidasDeTeste, length partidasDeTeste)
      (6, 5, 15)
  , testar "campeonato de teste: nenhum time joga duas vezes na mesma rodada"
      (all rodadaSemRepeticao [1 .. 5]) True
  , testar "campeonato de teste: tem um empate em 0 x 0"
      (any (\p -> golsMandante p == 0 && golsVisitante p == 0) partidasDeTeste) True
  , testar "campeonato de teste: tem vitoria por 3 ou mais gols"
      (any ((>= 3) . diferencaGols) partidasDeTeste) True
  ]

-- ---------------------------------------------------------------------
-- Camada 2: classificação e estatísticas
-- ---------------------------------------------------------------------

testesCamada2 :: [IO Bool]
testesCamada2 =
  [ testar "pontos: vitoria 3, empate 1, derrota 0"
      (map pontos [Vitoria, Empate, Derrota]) [3, 1, 0]
  , testar "linhaDoTime do Flamengo, invicto (1V 4E 0D, 8 x 6 gols)"
      (linhaDoTime partidasDeTeste "Flamengo") (Linha "Flamengo" 5 1 4 0 8 6)
  , testar "linhaDoTime de um time que nao jogou e a linha zerada"
      (linhaDoTime partidasDeTeste "Vasco") (linhaVazia "Vasco")
  , testar "pontosLinha e saldo do Botafogo (10 pontos, +5)"
      (pontosLinha botafogo, saldo botafogo) (10, 5)
  , testar "saldo negativo do Fortaleza (5 - 7 = -2)"
      (saldo fortaleza) (-2)
  , testar "aproveitamento do Palmeiras: 9 de 15 pontos = 60%"
      (aproveitamento (linhaDe "Palmeiras" tabelaFinal)) 60
  , testar "aproveitamento de quem nao jogou e 0 (sem divisao por zero)"
      (aproveitamento (linhaVazia "Vasco")) 0
  , testar "classificacao completa do campeonato de teste (conferida a mao)"
      (classificacao partidasDeTeste) tabelaFinal
  , testar "tabela final tem times empatados em pontos"
      (map nomesDoPar (empatesEmPontos tabelaFinal))
      [("Fortaleza", "Flamengo"), ("Internacional", "Cruzeiro")]
  , testar "Fortaleza x Flamengo (7 pts): decide o numero de vitorias (2 x 1)"
      (criterioDecisivo fortaleza flamengo) (Just "vitorias")
  , testar "...mesmo o Flamengo tendo saldo melhor (+2 x -2): vitorias vem antes"
      (saldo flamengo > saldo fortaleza, posicaoFinal "Fortaleza", posicaoFinal "Flamengo")
      (True, 3, 4)
  , testar "Internacional x Cruzeiro (4 pts, 1 V, saldo -4): decidem os gols marcados"
      (criterioDecisivo internacional cruzeiro) (Just "gols marcados")
  , testar "...e nao a ordem alfabetica, que poria o Cruzeiro na frente"
      (posicaoFinal "Internacional", posicaoFinal "Cruzeiro") (5, 6)
  , testar "times iguais em todos os criterios ficam em ordem alfabetica"
      (map time (classificacao [Partida 1 "Vasco" 1 1 "Bahia"])) ["Bahia", "Vasco"]
  , testar "classificacao (ateRodada 3 ...) conferida a mao"
      (classificacao (ateRodada 3 partidasDeTeste)) tabelaRodada3
  , testar "rodada 3: Palmeiras x Botafogo (6 pts, 2 V) decidido pelo saldo de gols"
      (criterioDecisivo (linhaDe "Palmeiras" tabelaRodada3) (linhaDe "Botafogo" tabelaRodada3))
      (Just "saldo de gols")
  , testar "a tabela da rodada 3 e diferente da final (lideres diferentes)"
      (map time (take 1 tabelaRodada3), map time (take 1 tabelaFinal))
      (["Palmeiras"], ["Botafogo"])
  , testar "ateRodada 2 devolve so as partidas das rodadas 1 e 2"
      (map rodada (ateRodada 2 partidasDeTeste)) [1, 1, 1, 2, 2, 2]
  , testar "ateRodada 0 nao tem partidas"
      (ateRodada 0 partidasDeTeste) []
  , testar "maiorGoleada do campeonato: Palmeiras 4 x 0 Cruzeiro"
      (maiorGoleada partidasDeTeste) (Just (Partida 2 "Palmeiras" 4 0 "Cruzeiro"))
  , testar "maiorGoleada com diferencas iguais fica com a primeira partida"
      (maiorGoleada [Partida 1 "Bahia" 3 0 "Vasco", Partida 2 "Vasco" 4 1 "Bahia"])
      (Just (Partida 1 "Bahia" 3 0 "Vasco"))
  , testar "mediaGols do campeonato: 43 gols em 15 partidas"
      (mediaGols partidasDeTeste) (Just (43 / 15))
  , testar "maiorGoleada [] e Nothing"
      (maiorGoleada []) Nothing
  , testar "mediaGols [] e Nothing"
      (mediaGols []) Nothing
  , testar "classificacao [] e [] (campeonato vazio nao quebra)"
      (classificacao []) []
  ]
  where
    botafogo      = linhaDe "Botafogo" tabelaFinal
    fortaleza     = linhaDe "Fortaleza" tabelaFinal
    flamengo      = linhaDe "Flamengo" tabelaFinal
    internacional = linhaDe "Internacional" tabelaFinal
    cruzeiro      = linhaDe "Cruzeiro" tabelaFinal
    nomesDoPar (a, b) = (time a, time b)

-- ---------------------------------------------------------------------
-- Camada 3: leitura, validação e formatação
-- ---------------------------------------------------------------------

testesCamada3 :: [IO Bool]
testesCamada3 =
  [ testar "separar quebra a linha nos separadores"
      (separar ';' "1;Botafogo;1;2;Palmeiras") ["1", "Botafogo", "1", "2", "Palmeiras"]
  , testar "separar preserva campos vazios, inclusive nas pontas"
      (separar ';' ";a;;b;") ["", "a", "", "b", ""]
  , testar "separar sem separador devolve um unico campo"
      (separar ';' "Botafogo") ["Botafogo"]
  , testar "lerPartida aceita linha valida, ignorando espacos e o \\r do Windows"
      (lerPartida 1 " 2 ; Palmeiras ; 4 ; 0 ; Cruzeiro \r")
      (Right (Partida 2 "Palmeiras" 4 0 "Cruzeiro"))
  , testar "lerCampeonato sobre a entrada valida devolve Right com as 15 partidas"
      (lerCampeonato dadosCampeonato) (Right partidasDeTeste)
  , testar "lerCampeonato de um texto so com comentarios devolve Right []"
      (lerCampeonato dadosSemPartidas) (Right [])
  , testar "lerCampeonato do texto vazio devolve Right []"
      (lerCampeonato "") (Right [])
  , testar "o mesmo confronto em rodadas diferentes e permitido (returno)"
      (length <$> lerCampeonato "1;Bahia;1;0;Vasco\n2;Vasco;2;2;Bahia\n") (Right 2)
    -- um teste para cada construtor de Erro
  , testar "CamposInvalidos: linha com 4 campos"
      (lerPartida 4 "1;Fortaleza;1;1") (Left (CamposInvalidos 4 4))
  , testar "CamposInvalidos: separador sobrando no fim (6 campos)"
      (lerPartida 2 "1;Bahia;1;0;Vasco;") (Left (CamposInvalidos 2 6))
  , testar "NumeroInvalido: placar \"dois\""
      (lerPartida 3 "1;Flamengo;dois;0;Cruzeiro") (Left (NumeroInvalido 3 "dois"))
  , testar "NumeroInvalido: placar \"2a\" (read lancaria excecao aqui)"
      (lerPartida 3 "1;Flamengo;2a;0;Cruzeiro") (Left (NumeroInvalido 3 "2a"))
  , testar "NumeroInvalido: rodada que nao e numero"
      (lerPartida 1 "um;Botafogo;2;1;Palmeiras") (Left (NumeroInvalido 1 "um"))
  , testar "NumeroInvalido: formatos que readMaybe sozinho aceitaria"
      (map (lerPartida 1) ["1;Bahia;(3);0;Vasco", "1;Bahia;0x10;0;Vasco"])
      [Left (NumeroInvalido 1 "(3)"), Left (NumeroInvalido 1 "0x10")]
  , testar "NumeroInvalido: numero grande demais para Int (sem estouro)"
      (lerPartida 1 "1;Bahia;99999999999999999999;0;Vasco")
      (Left (NumeroInvalido 1 "99999999999999999999"))
  , testar "PlacarNegativo: gols do mandante -1"
      (lerPartida 5 "2;Palmeiras;-1;0;Botafogo") (Left (PlacarNegativo 5))
  , testar "MesmoTime: time jogando contra si mesmo"
      (lerPartida 6 "2;Cruzeiro;1;1;Cruzeiro") (Left (MesmoTime 6 "Cruzeiro"))
  , testar "TimeRepetidoNaRodada: Botafogo escalado duas vezes na rodada 1"
      (lerCampeonato "1;Botafogo;1;0;Palmeiras\n1;Flamengo;2;2;Botafogo\n")
      (Left (TimeRepetidoNaRodada 1 "Botafogo"))
  , testar "RodadaInvalida: rodada 0"
      (lerPartida 7 "0;Internacional;2;0;Fortaleza") (Left (RodadaInvalida 7 0))
  , testar "TimeVazio: nome do mandante em branco"
      (lerPartida 8 "2; ;3;0;Flamengo") (Left (TimeVazio 8))
    -- relatórios de erro
  , testar "a linha do erro conta os comentarios e as linhas em branco"
      (lerCampeonato "# cabecalho\n\n1;Botafogo;dois;1;Palmeiras\n")
      (Left (NumeroInvalido 3 "dois"))
  , testar "lerCampeonato para no primeiro erro da entrada com erros"
      (lerCampeonato dadosComErros) (Left (NumeroInvalido 3 "dois"))
  , testar "todosOsErros lista os 7 erros da entrada com erros, na ordem"
      (todosOsErros dadosComErros) errosEsperados
  , testar "todosOsErros da entrada valida e []"
      (todosOsErros dadosCampeonato) []
  , testar "o primeiro de todosOsErros e o erro devolvido por lerCampeonato"
      (take 1 (todosOsErros dadosComErros))
      (either (: []) (const []) (lerCampeonato dadosComErros))
  , testar "mensagemErro diz a linha do problema"
      (mensagemErro (NumeroInvalido 3 "dois")) "Linha 3: \"dois\" nao e um numero inteiro"
  , testar "mensagemErro diz a rodada da escalacao repetida"
      (mensagemErro (TimeRepetidoNaRodada 2 "Flamengo"))
      "Rodada 2: Flamengo esta escalado em mais de uma partida"
    -- formatação
  , testar "formatarDecimal: duas casas decimais e virgula"
      (map formatarDecimal [43 / 15, 60, 0, 200 / 3]) ["2,87", "60,00", "0,00", "66,67"]
  , testar "tabelaFormatada: cabecalho e linha do lider"
      (take 2 (lines (tabelaFormatada tabelaFinal)))
      [ "Pos  Time           Pts   J   V   E   D   GP   GC   SG    Aprov"
      , "  1  Botafogo        10   5   3   1   1   10    5   +5   66,67%"
      ]
  , testar "tabelaFormatada: cabecalho mais uma linha por time"
      (length (lines (tabelaFormatada tabelaFinal))) 7
  , testar "tabelaFormatada de uma tabela vazia nao quebra"
      (tabelaFormatada []) "(tabela vazia: nenhuma partida registrada)\n"
  ]
