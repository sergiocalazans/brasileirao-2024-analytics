{-
  Módulo: Tipos (Camada 1)
  Descrição: Define os tipos algébricos e as consultas básicas
             sobre times, partidas e dados disciplinares do campeonato.

  Os tipos foram escolhidos para que erros comuns nem cheguem a compilar:
    * Resultado é um tipo soma: só existem Vitoria, Empate e Derrota
      (um "v" minúsculo compilaria como String, mas não como Resultado);
    * Partida e Linha são records: os nomes ajudam a distinguir os campos,
      mas trocar dois valores Int ainda compila e exige testes;
    * Linha guarda só contagens. Pontos, saldo e aproveitamento são
      calculados na Camada 2 e por isso nunca ficam inconsistentes.
-}
module Tipos
  ( -- * Tipos do domínio
    Time
  , Resultado (..)
  , Partida (..)
  , Linha (..)
  , Cartoes (..)
    -- * Consultas sobre uma partida
  , participou
  , golsMarcados
  , golsSofridos
  , resultadoPara
  , amarelosNaPartida
  , vermelhosNaPartida
    -- * Consultas sobre o campeonato
  , times
  ) where

import Data.List (nub, sort)

-- | Nome de um time.
type Time = String

-- | Resultado de uma partida do ponto de vista de um dos times.
data Resultado = Vitoria | Empate | Derrota
  deriving (Show, Eq)

-- | Uma partida, com os campos na mesma ordem da linha de entrada.
data Partida = Partida
  { rodada        :: Int   -- ^ número da rodada (1, 2, 3, ...)
  , mandante      :: Time  -- ^ time que joga em casa
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time  -- ^ time que joga fora
  } deriving (Show, Eq)

-- | Uma linha da tabela de classificação: as contagens acumuladas de um time.
data Linha = Linha
  { time       :: Time
  , jogos      :: Int
  , vitorias   :: Int
  , empates    :: Int
  , derrotas   :: Int
  , golsPro    :: Int  -- ^ gols marcados
  , golsContra :: Int  -- ^ gols sofridos
  } deriving (Show, Eq)

-- | Contagem disciplinar simples (cartões amarelos e vermelhos).
data Cartoes = Cartoes
  { amarelos :: Int
  , vermelhos :: Int
  } deriving (Show, Eq)

-- | Verdadeiro se o time jogou a partida, como mandante ou como visitante.
participou :: Time -> Partida -> Bool
participou t p = t == mandante p || t == visitante p

-- | Gols que o time marcou na partida (0 se ele não jogou).
golsMarcados :: Time -> Partida -> Int
golsMarcados t p
  | t == mandante p  = golsMandante p
  | t == visitante p = golsVisitante p
  | otherwise        = 0

-- | Gols que o time sofreu na partida (0 se ele não jogou).
golsSofridos :: Time -> Partida -> Int
golsSofridos t p
  | t == mandante p  = golsVisitante p
  | t == visitante p = golsMandante p
  | otherwise        = 0

-- | Resultado da partida do ponto de vista do time; Nothing se ele não jogou.
resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t p
  | participou t p = Just (resultadoDoPlacar (golsMarcados t p) (golsSofridos t p))
  | otherwise      = Nothing

-- | Traduz a comparação entre gols marcados e sofridos em um Resultado.
resultadoDoPlacar :: Int -> Int -> Resultado
resultadoDoPlacar marcados sofridos = case compare marcados sofridos of
  GT -> Vitoria
  EQ -> Empate
  LT -> Derrota

-- | Cartões amarelos de um time em uma partida sem registro disciplinar explícito (0).
amarelosNaPartida :: Time -> Partida -> Int
amarelosNaPartida _ _ = 0

-- | Cartões vermelhos de um time em uma partida sem registro disciplinar explícito (0).
vermelhosNaPartida :: Time -> Partida -> Int
vermelhosNaPartida _ _ = 0

-- | Todos os times do campeonato, sem repetição e em ordem alfabética.
times :: [Partida] -> [Time]
times = sort . nub . concatMap (\p -> [mandante p, visitante p])