{-
  Módulo: Dados
  Descrição: Armazena os dados de teste do campeonato,
             incluindo partidas e resultados por rodada.

  Os dados ficam no próprio código, como String, no mesmo formato de um
  arquivo de entrada (o playground não tem entrada pelo teclado). O mesmo
  campeonato está em data/teste.txt, para testar a leitura de arquivo.
  Os textos usam apenas caracteres ASCII para imprimir corretamente em
  qualquer console (veja docs/decisoes.md).
-}
module Dados
  ( dadosCampeonato
  , dadosComErros
  , dadosSemPartidas
  ) where

-- | Campeonato de teste (fictício, com clubes da Série A 2024): 6 times,
--   turno único de 5 rodadas com 3 jogos cada; ninguém joga duas vezes na
--   mesma rodada. Os placares foram escolhidos para cobrir os casos de borda:
--
--   * empate em 0 x 0 (rodada 1) e empates com gols (2 x 2 e 3 x 3);
--   * goleada por 4 gols (Palmeiras 4 x 0 Cruzeiro) e outra por 3;
--   * Fortaleza e Flamengo terminam com 7 pontos: decide o número de
--     vitórias (2 x 1), mesmo com o Flamengo invicto e com saldo melhor;
--   * Internacional e Cruzeiro terminam com 4 pontos, 1 vitória e saldo -4:
--     decidem os gols marcados (7 x 5);
--   * após a 3ª rodada, Palmeiras e Botafogo têm 6 pontos e 2 vitórias:
--     decide o saldo, e o líder da 3ª rodada não é o campeão.
dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# Campeonato de teste: 6 times, 5 rodadas (turno unico)"
  , "# rodada;mandante;gols mandante;gols visitante;visitante"
  , ""
  , "# Rodada 1"
  , "1;Botafogo;1;2;Palmeiras"
  , "1;Fortaleza;0;1;Internacional"
  , "1;Flamengo;0;0;Cruzeiro"
  , ""
  , "# Rodada 2"
  , "2;Internacional;1;3;Botafogo"
  , "2;Palmeiras;4;0;Cruzeiro"
  , "2;Fortaleza;2;2;Flamengo"
  , ""
  , "# Rodada 3"
  , "3;Botafogo;2;1;Cruzeiro"
  , "3;Internacional;3;3;Flamengo"
  , "3;Palmeiras;0;1;Fortaleza"
  , ""
  , "# Rodada 4"
  , "4;Flamengo;1;1;Botafogo"
  , "4;Cruzeiro;1;2;Fortaleza"
  , "4;Internacional;1;2;Palmeiras"
  , ""
  , "# Rodada 5"
  , "5;Botafogo;3;0;Fortaleza"
  , "5;Flamengo;2;0;Palmeiras"
  , "5;Cruzeiro;3;1;Internacional"
  ]

-- | Entrada com erros de digitação: cada linha inválida provoca um
--   construtor diferente de Erro (o número da linha está à direita).
dadosComErros :: String
dadosComErros = unlines
  [ "# Entrada com erros de digitacao"      -- linha 1: comentário
  , "1;Botafogo;2;1;Palmeiras"              -- linha 2: válida
  , "1;Flamengo;dois;0;Cruzeiro"            -- linha 3: NumeroInvalido
  , "1;Fortaleza;1;1"                       -- linha 4: CamposInvalidos (4 campos)
  , "2;Palmeiras;-1;0;Botafogo"             -- linha 5: PlacarNegativo
  , "2;Cruzeiro;1;1;Cruzeiro"               -- linha 6: MesmoTime
  , "0;Internacional;2;0;Fortaleza"         -- linha 7: RodadaInvalida
  , "2;;3;0;Flamengo"                       -- linha 8: TimeVazio
  , "2;Flamengo;0;0;Fortaleza"              -- linha 9: válida
  , "2;Flamengo;1;0;Internacional"          -- linha 10: Flamengo de novo na rodada 2
  ]

-- | Campeonato que ainda não tem partidas: só comentários e linhas em branco.
dadosSemPartidas :: String
dadosSemPartidas = unlines
  [ "# Campeonato sem partidas registradas"
  , ""
  , "# rodada;mandante;gols mandante;gols visitante;visitante"
  ]
