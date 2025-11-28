/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |18/09/2017| Chamado 21480. Incluido filtro para puxar somente mensalista e estagiario
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE019
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/06/2017
Descrição---------: Carrega cracha do funcionario a partir do pis - Chamado 21427
Parametros--------: _cpis - pis do funcionário
Retorno-----------: _ccracha - cracha do funcionario
===============================================================================================================================
*/
User Function MGPE019(_cpis)

Local _ccracha := Space(8)
Local _cQuery := ""
Local _cAliasSRA	 

If Empty(_cpis)

	Return Space(8)
	
EndIf

_cQuery := " SELECT" 
_cQuery += "    R_E_C_N_O_  REC"
_cQuery += " FROM "+ RetSqlName("SRA") +" SRA "
_cQuery += " WHERE "
_cQuery += "     SRA.D_E_L_E_T_ = ' ' "        
_cQuery += " AND SRA.RA_FILIAL  = '"+ xFilial("SRA") +"' "
_cQuery += " AND SRA.RA_PIS  = '" + AllTrim(_cpis) + "' " 
_cQuery += " AND SRA.RA_SITFOLH <> 'D'" 
_cQuery += " AND (SRA.RA_CATFUNC = 'M' OR SRA.RA_CATFUNC = 'E')" 


_cAliasSRA	:= GetNextAlias()   	
If Select(_cAliasSRA) > 0
	(_cAliasSRA)->( DBCloseArea() )
EndIf
 
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasSRA , .T. , .F. )

If !(_cAliasSRA)->(Eof())

   SRA->(DBGoTo((_cAliasSRA)->REC))
  _ccracha := SRA->RA_CRACHA

EndIf

If Select(_cAliasSRA) > 0
	(_cAliasSRA)->( DBCloseArea() )
EndIf

Return _ccracha

