/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Removidos os Warning na compilação da release 12.1.25. Chamado 28346
Lucas Borges  |11/03/2022| Incluído tratamento para Z-Plataformas. Chamado 39460
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM006
Autor-------------: Cleiton Campos
Data da Criacao---: 14/07/2008                                    .
Descrição---------: Codificação do Cadastro de Fornecedores - Código da Loja
Parametros--------: _pcCGC    = Devera ser passado o conteudo do campo A2_CGC.
                    cCodigo   = Devera ser passado o conteudo do campo A2_COD.
                    cClass    = Devera ser passado o conteudo do campo A2_I_CLASS.
Retorno-----------: _cRet     = Código que deverá ser gravado no campo A2_LOJA.
===============================================================================================================================
*/
User Function ACOM006( _pcCNPJ , cCodigo , cClass )

Local _aArea := FWGetArea()
Local _cQuery := ""

Local _cRetorno := ""

If cClass $ 'P/Z'

	If Len(AllTrim(_pcCNPJ)) > 10

		_cQuery := " SELECT MAX(A2_LOJA) AS LOJA "
		_cQuery += " FROM " + RetSqlName("SA2")
		_cQuery += " WHERE D_E_L_E_T_ = ' '"
		_cQuery += " AND   A2_COD = '" + AllTrim(cCodigo) +"' "
		_cQuery := ChangeQuery(_cQuery)
		MPSysOpenQuery(_cQuery,"QRY")
		
		QRY->(DBGoTop())
		_cRetorno := StrZero(Val(QRY->LOJA)+1,4)
		QRY->(DBCloseArea())
	EndIf    

Else

	If Len(AllTrim(_pcCNPJ)) > 11  
		
		_cRetorno := SubStr(_pcCNPJ,9,4) 
		
	Else
		
		_cQuery := " SELECT MAX(A2_LOJA) AS LOJA "
		_cQuery += " FROM " + RetSqlName("SA2")
		_cQuery += " WHERE D_E_L_E_T_ = ' '"
		_cQuery += " AND   A2_COD = '" + AllTrim(cCodigo) +"' "
		_cQuery := ChangeQuery(_cQuery)
		MPSysOpenQuery(_cQuery,"QRY")
		
		QRY->(DBGoTop())
		_cRetorno := StrZero(Val(QRY->LOJA)+1,4)
		QRY->(DBCloseArea())

	EndIf

EndIf
 
If !MayIUseCode( "A2_COD"+ xFilial("SA2") + cCodigo + _cRetorno )  //verifica se esta na memoria, sendo usado
	MSGSTOP("Código "+ cCodigo + " loja " + _cRetorno + " já está sendo utilizado. Contacte o administrador do sistema." )
	Return .F.
EndIf                

// Grava log de acesso a rotina Cadastro de Fornecedores. 
// Geração do código da loja do fornecedor.
U_ITLOGACS('ACOM006')

FWRestArea(_aArea)  

Return(_cRetorno)
