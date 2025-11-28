/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"
                     
/*
===============================================================================================================================
Programa----------: MT242SCR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/09/2015
Descrição---------: Ponto de entrada de personalização da tela de desmontagem de produtos - MATA242 - Chamado 11725
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MT242SCR()

//ajusta número do documento
cdocumento := U_PEST001()

//trava campo de documento
ParamIXB[1]:ACONTROLS[24]:OGET:OGET:LACTIVE := .F.

Return

/*
===============================================================================================================================
Programa----------: PEST001
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/09/2015
Descrição---------: Retorna próximo número de D3_DOC ignorando documentos que comecem com caracter alfabético
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function PEST001()

Local _cQuery := "" 
Local _cAlias	:= GetNextAlias()
Local _cNovoDoc := StrZero( 1 , TamSX3('D3_DOC')[01] )

_cQuery := " SELECT MAX(D3_DOC) AS DOC "
_cQuery += " FROM  "+ RETSQLNAME('SD3') +" SD3 "
_cQuery += " WHERE "
_cQuery += "     SD3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SD3.D3_FILIAL  = '"+ xFilial("SD3") +"' "
_cQuery += " AND SubStr( SD3.D3_DOC , 1 , 1 ) IN ('0','1','2','3','4','5','6','7','8','9') "
	
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf
	
DBUseArea( .T. , 'TopConn' , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
	
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->DOC )
		
	_cNovoDoc := Soma1( (_cAlias)->DOC )
		
EndIf	


Return _cNovoDoc
