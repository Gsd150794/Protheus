/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 19/09/2019 | Revisão do fonte - Chamado 28346 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE002
Autor-------------: Heder José
Data da Criacao---: 12/01/2011
Descrição---------: Rotina desenvolvida para retornar a matricula a partir do cpf informado. Utilizada na importação de 
					variáveis (GPEA210 - GPEA200)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE002(_nCpf)

Local _cAlias	:= GetNextAlias()
Local _nContReg	:= 0
Local _lControl	:= .F.
Local _aArea	:= FWGetArea()
Private _nMat	:= ' '

BeginSql alias _cAlias
	SELECT RA_FILIAL, RA_MAT, RA_SITFOLH
	  FROM %Table:SRA% RA
	 WHERE D_E_L_E_T_ = ' '
	   AND RA_FILIAL = %xFilial:SRA%
	   AND RA_CATFUNC = 'M'
	   AND RA_CIC = %exp:_nCpf%
	 ORDER BY RA_MAT DESC
EndSql

COUNT To _nContReg
(_cAlias)->(DBGoTop())

If _nContReg == 1
	_nMat:= (_cAlias)->RA_MAT
	_lControl:= .T.
Else
	While (_cAlias)->(!Eof())
		If (_cAlias)->RA_SITFOLH <> 'D'
    		_nMat:= (_cAlias)->RA_MAT
			_lControl:= .T.
			Exit
		EndIf
		(_cAlias)->(DBSkip())
	EndDo
EndIf

If !_lControl
	(_cAlias)->(DBGoTop())
	_nMat:= (_cAlias)->RA_MAT
EndIf

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return(_nMat)
