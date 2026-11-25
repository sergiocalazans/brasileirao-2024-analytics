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
  textoReal <- readFile "data/brasileirao-2024.csv"
  textoTeste <- readFile "data/campeonato-teste.csv"
  textoLegado <- readFile "data/teste.txt"
  resultados <- concat <$> sequence
    [ grupo "Camada 1 - Tipos e consultas basicas" testesCamada1
    , grupo "Camada 2 - Classificacao e estatisticas" testesCamada2
    , grupo "Camada 3 - Leitura, validacao e formatacao" testesCamada3
    , grupo "Criterios avancados, desempates e disciplina" testesCriteriosEDisciplina
    , grupo "Integracao - Arquivos CSV" (testesArquivos textoReal textoTeste textoLegado)
    ]
  let total  = length resultados
      falhas = length (filter not resultados)
  putStrLn ("\n" ++ show (total - falhas) ++ " de " ++ show total ++ " testes passaram.")
  if falhas == 0 then exitSuccess else exitFailure

-- | Confere os arquivos entregues usando o parser e os calculos do programa.
testesArquivos :: String -> String -> String -> [IO Bool]
testesArquivos real controlado legado =
  [ testar "CSV controlado corresponde a Dados.hs"
      (lerCampeonato controlado) (Right partidasDeTeste)
  , testar "arquivo legado preserva o mesmo campeonato"
      (lerCampeonato legado) (lerCampeonato controlado)
  , testar "dataset real: 380 partidas, 20 times e 38 rodadas"
      ((\ps -> (length ps, length (times ps), ultimaRodada ps)) <$> partidas)
      (Right (380, 20, 38))
  , testar "dataset real nao tem erros ou times repetidos na rodada"
      (todosOsErros real) []
  , testar "tabela real completa confere com a classificacao publicada pela CBF"
      (classificacao <$> partidas) (Right tabelaReal)
  , testar "dataset real: 929 gols e media de 929/380"
      ((\ps -> (totalDeGols ps, mediaGols ps)) <$> partidas) (Right (929, Just (929 / 380)))
  , testar "dataset real: 190 partidas ate a rodada 19"
      (length . ateRodada 19 <$> partidas) (Right 190)
  , testar "dataset real: rodada intermediaria 10 tem 100 partidas"
      (length . ateRodada 10 <$> partidas) (Right 100)
  ]
  where
    partidas = lerCampeonato real

-- | Valores da CBF para a Serie A 2024; nomes seguem o CSV de origem.
--   Fonte: https://www.cbf.com.br/futebol-brasileiro/tabelas/campeonato-brasileiro/serie-a/2024
tabelaReal :: [Linha]
tabelaReal =
  [ Linha "Botafogo-RJ"   38 23 10  5 59 29
  , Linha "Palmeiras"     38 22  7  9 60 33
  , Linha "Flamengo"      38 20 10  8 61 42
  , Linha "Fortaleza"     38 19 11  8 53 39
  , Linha "Internacional" 38 18 11  9 53 36
  , Linha "Sao Paulo"     38 17  8 13 53 43
  , Linha "Corinthians"   38 15 11 12 54 45
  , Linha "Bahia"         38 15  8 15 49 49
  , Linha "Cruzeiro"      38 14 10 14 43 41
  , Linha "Vasco"         38 14  8 16 43 56
  , Linha "Vitoria"       38 13  8 17 45 52
  , Linha "Atletico-MG"   38 11 14 13 47 54
  , Linha "Fluminense"   38 12 10 16 33 39
  , Linha "Gremio"       38 12  9 17 44 50
  , Linha "Juventude"    38 11 12 15 48 59
  , Linha "Bragantino"   38 10 14 14 44 48
  , Linha "Athletico-PR" 38 11  9 18 40 46
  , Linha "Criciuma"     38  9 11 18 42 61
  , Linha "Atletico-GO"  38  7  9 22 29 58
  , Linha "Cuiaba"       38  6 12 20 29 49
  ]

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
  , testar "cartoes sem registro explicito retornam 0"
      (amarelosNaPartida "Botafogo" jogoFora, vermelhosNaPartida "Botafogo" jogoFora) (0, 0)
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
  , testar "confronto direto decide antes da ordem alfabetica"
      (map time (take 2 (classificacao partidasConfronto))) ["Z", "A"]
  , testar "explicacao identifica o confronto direto"
      (criterioDecisivoCampeonato partidasConfronto
        (linhaDoTime partidasConfronto "Z") (linhaDoTime partidasConfronto "A"))
      (Just "confronto direto")
  , testar "tres times empatados em pontos nao usam confronto direto"
      (map time (filter (\l -> time l `elem` ["A", "Z"]) (classificacao empateTriplo)))
      ["A", "Z"]
  , testar "a ordem da entrada nao altera a classificacao com confronto direto"
      (classificacao (reverse partidasConfronto)) (classificacao partidasConfronto)
  ]
  where
    botafogo      = linhaDe "Botafogo" tabelaFinal
    fortaleza     = linhaDe "Fortaleza" tabelaFinal
    flamengo      = linhaDe "Flamengo" tabelaFinal
    internacional = linhaDe "Internacional" tabelaFinal
    cruzeiro      = linhaDe "Cruzeiro" tabelaFinal
    nomesDoPar (a, b) = (time a, time b)
    empateTriplo = partidasConfronto ++ [Partida 1 "E" 3 0 "F", Partida 2 "F" 0 3 "E"]

-- A e Z: 6 pontos, 2 vitorias, saldo 0 e 2 gols pro; Z venceu os dois confrontos.
partidasConfronto :: [Partida]
partidasConfronto =
  [ Partida 1 "Z" 1 0 "A", Partida 2 "A" 0 1 "Z"
  , Partida 3 "A" 1 0 "C", Partida 3 "Z" 0 1 "D"
  , Partida 4 "A" 1 0 "D", Partida 4 "Z" 0 1 "C"
  ]

-- Confronto direto incompleto: apenas 1 partida entre Z e A (sem jogo de volta).
partidasConfrontoIncompleto :: [Partida]
partidasConfrontoIncompleto =
  [ Partida 1 "Z" 1 0 "A"
  , Partida 2 "A" 1 0 "C", Partida 2 "Z" 0 1 "D"
  , Partida 3 "A" 1 0 "D", Partida 3 "Z" 0 1 "C"
  ]

-- Empate entre 3 clubes em pontos (9 pts), vitorias (3) e saldo (+2),
-- separados por gols marcados (X: 8 GP, Y: 7 GP, W: 6 GP).
partidasTresClubes :: [Partida]
partidasTresClubes =
  [ Partida 1 "X" 4 2 "D1", Partida 1 "Y" 3 1 "D2", Partida 1 "W" 2 0 "D3"
  , Partida 2 "X" 2 1 "D2", Partida 2 "Y" 2 1 "D3", Partida 2 "W" 2 1 "D1"
  , Partida 3 "X" 2 1 "D3", Partida 3 "Y" 2 1 "D1", Partida 3 "W" 2 1 "D2"
  ]

-- ---------------------------------------------------------------------
-- Critérios avançados, desempates e disciplina
-- ---------------------------------------------------------------------

testesCriteriosEDisciplina :: [IO Bool]
testesCriteriosEDisciplina =
  [ testar "desempate por numero de vitorias: Fortaleza (2 V) acima do Flamengo (1 V)"
      (criterioDecisivo (linhaDe "Fortaleza" tabelaFinal) (linhaDe "Flamengo" tabelaFinal))
      (Just "vitorias")
  , testar "desempate por saldo de gols: Palmeiras (+4) acima do Botafogo (+2) na rodada 3"
      (criterioDecisivo (linhaDe "Palmeiras" tabelaRodada3) (linhaDe "Botafogo" tabelaRodada3))
      (Just "saldo de gols")
  , testar "desempate por gols marcados: Internacional (7 GP) acima do Cruzeiro (5 GP)"
      (criterioDecisivo (linhaDe "Internacional" tabelaFinal) (linhaDe "Cruzeiro" tabelaFinal))
      (Just "gols marcados")
  , testar "confronto direto entre dois clubes (Z e A) com ida e volta"
      (criterioDecisivoCampeonato partidasConfronto
        (linhaDoTime partidasConfronto "Z") (linhaDoTime partidasConfronto "A"))
      (Just "confronto direto")
  , testar "empate entre tres clubes ordena corretamente sem usar confronto direto"
      (map time (take 3 (classificacao partidasTresClubes)))
      ["X", "Y", "W"]
  , testar "confronto direto sem as duas partidas nao decide pelo confronto direto"
      (criterioDecisivoCampeonato partidasConfrontoIncompleto
        (linhaDoTime partidasConfrontoIncompleto "Z")
        (linhaDoTime partidasConfrontoIncompleto "A"))
      (Just "ordem alfabetica")
  , testar "empate identico em todos os criterios objetivos depende de sorteio / desempate final"
      (empateDependeDeSorteio [Partida 1 "A" 1 1 "B"]
        (linhaDoTime [Partida 1 "A" 1 1 "B"] "A")
        (linhaDoTime [Partida 1 "A" 1 1 "B"] "B"))
      True
  , testar "cartoes amarelos e vermelhos sao contabilizados por clube"
      ( totalAmarelos registrosDisciplinares "Botafogo"
      , totalVermelhos registrosDisciplinares "Botafogo"
      )
      (3, 1)
  , testar "ausencia de dados disciplinares retorna zero sem falhar"
      ( totalAmarelos [] "Botafogo"
      , totalVermelhos [] "Botafogo"
      , cartoesDoTime [] "Botafogo"
      )
      (0, 0, Cartoes 0 0)
  ]
  where
    registrosDisciplinares =
      [ ("Botafogo", 2, 0)
      , ("Palmeiras", 1, 1)
      , ("Botafogo", 1, 1)
      ]

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
  , testar "todosOsErros acumula problemas independentes na mesma linha"
      (todosOsErros "0;Bahia;-1;dois;Bahia")
      [NumeroInvalido 1 "dois", RodadaInvalida 1 0, PlacarNegativo 1, MesmoTime 1 "Bahia"]
  , testar "todosOsErros informa cada campo numerico invalido"
      (todosOsErros "x;Bahia;y;z;Vasco")
      [NumeroInvalido 1 "x", NumeroInvalido 1 "y", NumeroInvalido 1 "z"]
  , testar "todosOsErros encontra repeticao mesmo com placar invalido"
      (todosOsErros "1;Bahia;dois;0;Vasco\n1;Bahia;1;0;Flamengo")
      [NumeroInvalido 1 "dois", TimeRepetidoNaRodada 1 "Bahia"]
  , testar "todosOsErros nao confunde MesmoTime com repeticao entre partidas"
      (todosOsErros "1;Bahia;0;0;Bahia") [MesmoTime 1 "Bahia"]
  , testar "todosOsErros nao repete o mesmo erro de escalacao"
      (todosOsErros "1;Bahia;0;0;Vasco\n1;Bahia;1;0;Flamengo\n1;Bahia;2;0;Cruzeiro")
      [TimeRepetidoNaRodada 1 "Bahia"]
  , testar "integracao: texto valido produz a tabela final esperada"
      (classificacao <$> lerCampeonato dadosCampeonato) (Right tabelaFinal)
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