{-
  Módulo: Leitura (Camada 3)
  Descrição: Realiza a leitura, validação e formatação dos dados,
             utilizando Maybe e Either para tratar erros.

  O módulo é todo puro: recebe texto e devolve valores. Nenhuma entrada,
  por pior que seja, lança exceção: cada problema vira um Left com um Erro
  que diz a linha (ou a rodada) em que ele está. Números são lidos com
  readMaybe, nunca com read.

  Formato de cada linha (linhas em branco e iniciadas por # são ignoradas):
      rodada;mandante;gols mandante;gols visitante;visitante
-}
module Leitura
  ( -- * Erros de leitura
    Erro (..)
  , mensagemErro
    -- * Leitura e validação
  , separar
  , lerPartida
  , lerCampeonato
  , todosOsErros
    -- * Formatação para impressão
  , tabelaFormatada
  , formatarPartida
  , formatarDecimal
  , alinharEsquerda
  ) where

import Data.Char (isDigit, isSpace)
import Data.Either (partitionEithers)
import Data.List (dropWhileEnd, inits, nub)
import Data.Maybe (listToMaybe)
import Text.Read (readMaybe)

import Classificacao (aproveitamento, pontosLinha, saldo)
import Tipos

-- ---------------------------------------------------------------------
-- Erros
-- ---------------------------------------------------------------------

-- | Tudo o que pode estar errado no texto de entrada. Cada construtor
--   carrega a linha do problema (ou a rodada, na escalação repetida).
data Erro
  = CamposInvalidos Int Int        -- ^ linha; quantos campos ela tem (o certo são 5)
  | NumeroInvalido Int String      -- ^ linha; texto que deveria ser um número inteiro
  | PlacarNegativo Int             -- ^ linha
  | MesmoTime Int Time             -- ^ linha; time escalado contra si mesmo
  | TimeRepetidoNaRodada Int Time  -- ^ rodada; time que joga mais de uma vez nela
  | RodadaInvalida Int Int         -- ^ linha; rodada lida (precisa ser 1 ou mais)
  | TimeVazio Int                  -- ^ linha com nome de time em branco
  deriving (Show, Eq)

-- | Mensagem legível de um erro, sempre dizendo onde ele está.
mensagemErro :: Erro -> String
mensagemErro erro = case erro of
  CamposInvalidos n qtd    -> naLinha n ("esperados 5 campos separados por ';', encontrados " ++ show qtd)
  NumeroInvalido n ""      -> naLinha n "campo numerico vazio"
  NumeroInvalido n texto   -> naLinha n (show texto ++ " nao e um numero inteiro")
  PlacarNegativo n         -> naLinha n "o placar nao pode ter gols negativos"
  MesmoTime n t            -> naLinha n (t ++ " nao pode jogar contra si mesmo")
  TimeRepetidoNaRodada r t -> "Rodada " ++ show r ++ ": " ++ t ++ " esta escalado em mais de uma partida"
  RodadaInvalida n r       -> naLinha n ("rodada " ++ show r ++ " invalida (deve ser 1 ou mais)")
  TimeVazio n              -> naLinha n "nome de time em branco"
  where
    naLinha n texto = "Linha " ++ show n ++ ": " ++ texto

-- ---------------------------------------------------------------------
-- Leitura e validação
-- ---------------------------------------------------------------------

-- | Quebra o texto em campos a cada separador, preservando campos vazios:
--   separar ';' "1;;2" == ["1", "", "2"]. A dobra percorre o texto da
--   direita para a esquerda guardando o campo em construção e os campos já
--   completos; no fim, uncurry (:) junta os dois.
separar :: Char -> String -> [String]
separar separador = uncurry (:) . foldr passo ("", [])
  where
    passo c (campo, campos)
      | c == separador = ("", campo : campos)
      | otherwise      = (c : campo, campos)

-- | Remove espaços do início e do fim (inclusive o \r de arquivos do Windows).
aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace

-- | Linhas com dados, numeradas a partir de 1. Linhas em branco e
--   comentários (#) são descartados, mas contam na numeração, para que a
--   mensagem de erro aponte a linha certa do texto.
linhasDeDados :: String -> [(Int, String)]
linhasDeDados = filter (temDados . snd) . zip [1 ..] . lines
  where
    temDados linha = case aparar linha of
      ""      -> False
      '#' : _ -> False
      _       -> True

-- | Converte uma linha (com o seu número) em partida. O case só confere a
--   quantidade de campos; as validações são encadeadas pela notação do na
--   mônada Either: o primeiro Left interrompe o resto, sem "escadinha".
lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha = case map aparar (separar ';' linha) of
  [campoRodada, campoMandante, campoGolsM, campoGolsV, campoVisitante] -> do
    numRodada <- lerInteiro n campoRodada
    golsM     <- lerInteiro n campoGolsM
    golsV     <- lerInteiro n campoGolsV
    casa      <- lerTime n campoMandante
    fora      <- lerTime n campoVisitante
    exigir (numRodada >= 1)           (RodadaInvalida n numRodada)
    exigir (golsM >= 0 && golsV >= 0) (PlacarNegativo n)
    exigir (casa /= fora)             (MesmoTime n casa)
    return (Partida numRodada casa golsM golsV fora)
  campos -> Left (CamposInvalidos n (length campos))

-- | Converte um campo em Int sem nunca lançar exceção. Cada etapa pode
--   falhar com Nothing, e >>= (mônada Maybe) para na primeira falha:
--     1. o texto precisa ter só algarismos, com um '-' opcional na frente
--        (readMaybe sozinho aceitaria também "(3)" e "0x10");
--     2. readMaybe converte para Integer, que não estoura;
--     3. o valor precisa caber em um Int ("99999999999999999999" não cabe).
--   No fim, maybe transforma o Nothing em um Left com a linha do erro.
lerInteiro :: Int -> String -> Either Erro Int
lerInteiro n texto =
  maybe (Left (NumeroInvalido n texto)) Right (soAlgarismos texto >>= readMaybe >>= cabeEmInt)

-- | Devolve o texto se ele for um inteiro decimal: algarismos com '-' opcional.
soAlgarismos :: String -> Maybe String
soAlgarismos texto
  | not (null digitos) && all isDigit digitos = Just texto
  | otherwise                                 = Nothing
  where
    digitos = case texto of
      '-' : resto -> resto
      _           -> texto

-- | Converte um Integer em Int só se ele couber no intervalo de Int.
cabeEmInt :: Integer -> Maybe Int
cabeEmInt x
  | x >= toInteger (minBound :: Int) && x <= toInteger (maxBound :: Int) = Just (fromInteger x)
  | otherwise = Nothing

-- | Aceita qualquer nome de time que não esteja em branco.
lerTime :: Int -> String -> Either Erro Time
lerTime n nome
  | null nome = Left (TimeVazio n)
  | otherwise = Right nome

-- | Falha com o erro dado quando a condição é falsa.
exigir :: Bool -> Erro -> Either Erro ()
exigir condicao erro
  | condicao  = Right ()
  | otherwise = Left erro

-- | Lê o texto inteiro parando no primeiro erro: traverse aplica lerPartida
--   a cada linha dentro da mônada Either. Depois, confere as rodadas.
lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto = do
  partidas <- traverse (uncurry lerPartida) (linhasDeDados texto)
  verificarRodadas partidas

-- | Devolve as partidas se nenhum time joga duas vezes na mesma rodada.
verificarRodadas :: [Partida] -> Either Erro [Partida]
verificarRodadas partidas =
  maybe (Right partidas) Left (listToMaybe (errosDeRodada partidas))

-- | Um erro para cada time escalado mais de uma vez numa mesma rodada.
errosDeRodada :: [Partida] -> [Erro]
errosDeRodada = map (uncurry TimeRepetidoNaRodada) . repetidos . concatMap escalacoes
  where
    escalacoes p = [(rodada p, mandante p), (rodada p, visitante p)]

-- | Elementos que já tinham aparecido antes na lista (cada um uma vez só).
--   inits xs são os prefixos de xs, então zip xs (inits xs) junta cada
--   elemento com tudo o que veio antes dele.
repetidos :: Eq a => [a] -> [a]
repetidos xs = nub [x | (x, anteriores) <- zip xs (inits xs), x `elem` anteriores]

-- | Relatório com todos os erros do texto, e não só o primeiro: os erros de
--   cada linha (partitionEithers separa os Left dos Right) e, entre as
--   linhas válidas, os times escalados duas vezes na mesma rodada.
todosOsErros :: String -> [Erro]
todosOsErros texto = errosDeLinha ++ errosDeRodada partidasValidas
  where
    (errosDeLinha, partidasValidas) =
      partitionEithers (map (uncurry lerPartida) (linhasDeDados texto))

-- ---------------------------------------------------------------------
-- Formatação para impressão
-- ---------------------------------------------------------------------

-- | A tabela pronta para impressão: posição, time, pontos, jogos, vitórias,
--   empates, derrotas, gols pró, gols contra, saldo e aproveitamento.
tabelaFormatada :: [Linha] -> String
tabelaFormatada [] = "(tabela vazia: nenhuma partida registrada)\n"
tabelaFormatada linhas = unlines (cabecalho : zipWith linhaFormatada [1 :: Int ..] linhas)
  where
    -- largura da coluna de nomes: o maior nome ou o título "Time"
    largura = foldr (max . length . time) (length "Time") linhas
    cabecalho =
      alinharDireita 3 "Pos" ++ "  " ++ alinharEsquerda largura "Time"
        ++ concatMap (\(titulo, tamanho, _) -> alinharDireita tamanho titulo) colunas
    linhaFormatada pos l =
      alinharDireita 3 (show pos) ++ "  " ++ alinharEsquerda largura (time l)
        ++ concatMap (\(_, tamanho, valor) -> alinharDireita tamanho (valor l)) colunas

-- | Colunas numéricas da tabela: título, largura e como obter o valor.
--   Para incluir uma coluna nova, basta acrescentar uma linha aqui.
colunas :: [(String, Int, Linha -> String)]
colunas =
  [ ("Pts",   5, show . pontosLinha)
  , ("J",     4, show . jogos)
  , ("V",     4, show . vitorias)
  , ("E",     4, show . empates)
  , ("D",     4, show . derrotas)
  , ("GP",    5, show . golsPro)
  , ("GC",    5, show . golsContra)
  , ("SG",    5, comSinal . saldo)
  , ("Aprov", 9, (++ "%") . formatarDecimal . aproveitamento)
  ]

-- | Número com sinal explícito quando positivo: +5, 0, -2.
comSinal :: Int -> String
comSinal x
  | x > 0     = '+' : show x
  | otherwise = show x

-- | Completa o texto com espaços à esquerda até a largura pedida.
alinharDireita :: Int -> String -> String
alinharDireita n s = replicate (n - length s) ' ' ++ s

-- | Completa o texto com espaços à direita até a largura pedida.
alinharEsquerda :: Int -> String -> String
alinharEsquerda n s = s ++ replicate (n - length s) ' '

-- | Uma partida em uma linha: "Rodada 2: Palmeiras 4 x 0 Cruzeiro".
formatarPartida :: Partida -> String
formatarPartida p =
  "Rodada " ++ show (rodada p) ++ ": " ++ mandante p ++ " " ++ show (golsMandante p)
    ++ " x " ++ show (golsVisitante p) ++ " " ++ visitante p

-- | Número com duas casas decimais e vírgula (padrão brasileiro): 2.8667 -> "2,87".
formatarDecimal :: Double -> String
formatarDecimal x = sinal ++ show inteiros ++ "," ++ doisDigitos centesimos
  where
    total = round (abs x * 100) :: Int
    (inteiros, centesimos) = total `divMod` 100
    sinal = if x < 0 && total > 0 then "-" else ""
    doisDigitos d = if d < 10 then '0' : show d else show d
