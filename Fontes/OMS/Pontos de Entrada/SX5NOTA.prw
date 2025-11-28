/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 08/06/2018 | Ajuste na seleção das séries. Chamado 14156
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  | 27/06/2019 | Ajuste para loboguara - Chamado 29782
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 03/08/2020 | Ajuste na seleção das séries. Chamado 33714
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa--------: SX5NOTA
Autor-----------: Alexandre Villar
Data da Criacao-: 13/05/2014
===============================================================================================================================
Descrição-------: Ponto de entrada que valida as séries que serão habilitadas para cada tipo de emissão de documento fiscal
					Chamado: 6168 / 6224 - Melhorias no controle de séries de documentos
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: lRet -> Lódigo -> .T./.F. - Considera/Não considera a série da nota fiscal na geração.
===============================================================================================================================
*/
User Function SX5NOTA()

Local _aSeries	:= {}
Local _lRet		:= .F.
Local _nI 		:= 0
Local _cFunName := FunName()
//===========================================================================
//| Verifica o parâmetro que será utilizado para validação.                 |
//===========================================================================
Do Case
	Case _cFunName $ "MATA103"
		_aSeries := StrTokArr(SuperGetMV("IT_SERDENT",,"2"),";")
	Case _cFunName $ "U_MGLT009"
		_aSeries := StrTokArr(SuperGetMV("IT_SERDLEI",,"3"),";")
	Case _cFunName $ "MATA460/MATA460A/MATA460B/MATA461/MATA461A/MATA461B"
		_aSeries := StrTokArr(SuperGetMV("IT_SERDSAI",,"1"),";")
	Case _cFunName == "SPEDMDFE"
		_aSeries := StrTokArr(SuperGetMV("IT_SERDMDF",,"001"),";")
	Case _cFunName == "MFIS006"
		_aSeries := StrTokArr(SuperGetMV("IT_SERAJU",,"1"),";")
EndCase

//===========================================================================
//Carrega SX5 via query para não conflitar com sonarcube
//===========================================================================
_nrec := SX5->(Recno())

_cQuery := " SELECT X5_CHAVE CHAVE "
_cQuery += " FROM " + RetSqlName("SX5")
_cQuery += " WHERE D_E_L_E_T_ <> '*'"
_cQuery += " AND   R_E_C_N_O_ = " + AllTrim(Str(_nrec)) + " "
	
TcQuery _cQuery New Alias "QRY"

_cchave := QRY->CHAVE

QRY->(DBCloseArea())

//===========================================================================
//| Verifica se a Série está configurada para a rotina atual.               |
//===========================================================================
For _nI := 1 To Len(_aSeries)
	If AllTrim(_cchave) == _aSeries[_nI]
		_lRet := .T.
		Exit
	EndIf
Next _nI

Return( _lRet )
