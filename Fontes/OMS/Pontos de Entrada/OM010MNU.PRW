/*
=================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
=================================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
---------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
---------------------------------------------------------------------------------------------------------------------------------
Jerry         | 17/04/2020 | Ajustes para replicação de tabelas - Chamado 28370
---------------------------------------------------------------------------------------------------------------------------------
Jonathan      | 03/06/2020 | Nova função adicionada no menu - Chamado 32973
---------------------------------------------------------------------------------------------------------------------------------
Jerry         | 04/11/2020 | Validar novo campo de Tabela de Preço. Chamado 34582
---------------------------------------------------------------------------------------------------------------------------------
Julio Paz     | 05/04/2021 | Substituição do fonte MOMS037 pelo novo fonte AOMS122. Chamado 35936.
---------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  | 17/08/2021 | Retirar verificação de réplica de Filial e inclusão de campos novos na tabela de log. Chamado 37416
---------------------------------------------------------------------------------------------------------------------------------
Jerry         | 05/08/2022 | Rotina nova para Ativação, Inativação e alteração de vigência de Tabela de preço. Chamado: 40336
=================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"
#Include "TBICONN.CH"
 
/* 
===============================================================================================================================
Programa----------: OM010MNU
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2018
===============================================================================================================================
Descrição---------: PE que modifica menu do cadastro de tabela de preços - Chamado 24295 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/ 

User Function OM010MNU()


aRotina := 		   {{ OemToAnsi("Visualizar")           ,"VIEWDEF.OMSA010",0,MODEL_OPERATION_VIEW		,32,NIL},;	//
					{ OemToAnsi("Incluir")              ,"VIEWDEF.OMSA010",0,MODEL_OPERATION_INSERT	,32,NIL},;	//
					{ OemToAnsi("Alterar")              ,"Oms010Alt"	  ,0,MODEL_OPERATION_UPDATE	,32,NIL},;	//						
					{ OemToAnsi("Excluir")              ,"U_ITDA1EXC"	  ,0,MODEL_OPERATION_DELETE	,32,NIL},;	//
					{ OemToAnsi("Copiar")               ,"Oms010Cpy"	  ,0,9						,32,NIL},;  //
					{ OemToAnsi("Gerar")                ,"Oms010Ger"	  ,0,3,32,NIL},;  //		
					{ OemToAnsi("Reajuste")             ,"U_AOMS122"	  ,0,5,32,NIL},;   //		
					{ OemToAnsi("Histórico")            ,"U_MOMS038"	  ,0,5,32,NIL},;
					{ OemToAnsi("Importação Tab. Preço"),"U_MOMS053"      ,0,5,32,NIL},;
					{ OemToAnsi("Manutenção"),"U_MOMS067"      ,0,5,32,NIL},;					
					{ OemToAnsi("Listagem")             ,"U_ROMS061"	  ,0,5,32,NIL}} 				   

 
Return 

/*
===============================================================================================================================
Programa----------: ITDA1EXC
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2018
===============================================================================================================================
Descrição---------: Exclusão de tabela de preços personalizada
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ITDA1EXC()   
Local _nI		:= 0
Local _cQuery := ''
Local calias  := GetNextAlias()
Public _lexclui := .T.

//Testa se tabela não foi usada em pedido de vendas ativo
_cQuery := " SELECT count(c5_num) total"
_cQuery += " FROM "+ RetSqlName("SC5") +" SC5 "
_cQuery += " WHERE "
_cQuery += "     SC5.C5_I_TAB	= '"+ DA0->DA0_CODTAB +"' "
_cQuery += " AND    SC5.C5_NOTA	= ' '"
_cQuery += " AND SC5.D_E_L_E_T_	= ' ' "

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAlias , .T. , .F. )

If (cAlias)->(!Eof()) .And. (cAlias)->total > 0

 	U_ITMsg("Tabela de vendas não pode ser excluida pois está sendo usada em pedidos de vendas ativos","Atenção","Exclua ou altere os pedidos de vendas antes de excluir a tabela de preços",1)
 	Return
 	
EndIf

FWExecView("Exclusão de tabela de Preço", 'OMSA010', MODEL_OPERATION_VIEW)

If U_ITMsg("Deseja excluir tabela de preços " + DA0->DA0_CODTAB + "?", "Atenção","",2,2)

	BEGIN TRANSACTION

	//Guarda se é tabela replicada
	_ccodigo := DA0->DA0_CODTAB

	DA1->(DBSetOrder(1))
	_lfalha := .F.
	If DA1->(DBSeek(DA0->DA0_FILIAL+DA0->DA0_CODTAB))
	
		_anums := {}
	
		While DA0->DA0_FILIAL == DA1->DA1_FILIAL .And. DA0->DA0_CODTAB == DA1->DA1_CODTAB
		
			aAdd(_anums,DA1->(Recno()))
			
			DA1->(DBSkip())
			
		EndDo
		
		For _nI := 1 to Len(_anums)
		
			DA1->(DBGoTo(_anums[_nI]))
			
			//Grava log da exclusão
			RecLock("ZGS",.T.)
			ZGS->ZGS_FILIAL := xFilial("ZGS")
			ZGS->ZGS_ITEM   := DA1->DA1_ITEM
			ZGS->ZGS_DATA   := Date()
			ZGS->ZGS_HORA   := Time()
			ZGS->ZGS_USER   := cUserName
			ZGS->ZGS_MODULO := funname()	
			ZGS->ZGS_CODTAB := DA0->DA0_CODTAB
			ZGS->ZGS_DATDE 	:= DA0->DA0_DATDE
			ZGS->ZGS_HORADE	:= DA0->DA0_HORADE
			ZGS->ZGS_DATATE	:= DA0->DA0_DATATE
			ZGS->ZGS_HORATE	:= DA0->DA0_HORATE
			ZGS->ZGS_CONDPG	:= DA0->DA0_CONDPG
			ZGS->ZGS_TPHORA	:= DA0->DA0_TPHORA
			ZGS->ZGS_ATIVO 	:= DA0->DA0_ATIVO
			ZGS->ZGS_CODPRO	:= DA1->DA1_CODPRO
			ZGS->ZGS_GRUPO 	:= DA1->DA1_GRUPO
			ZGS->ZGS_PRCVEN	:= DA1->DA1_PRCVEN
			ZGS->ZGS_I_PRCA	:= DA1->DA1_I_PRCA
			ZGS->ZGS_PRCMAX	:= DA1->DA1_PRCMAX
			ZGS->ZGS_I_PRMP	:= DA1->DA1_I_PRMP
			ZGS->ZGS_I_PTBN	:= DA1->DA1_I_PTBN
			ZGS->ZGS_I_VIGI	:= DA1->DA1_I_VIGI
			ZGS->ZGS_I_VIGF	:= DA1->DA1_I_VIGF
			ZGS->ZGS_ODATDE := DA0->DA0_DATDE
			ZGS->ZGS_OHORAD := DA0->DA0_HORADE
			ZGS->ZGS_ODATAT := DA0->DA0_DATATE
			ZGS->ZGS_OHORAT := DA0->DA0_HORATE
			ZGS->ZGS_OCONDP := DA0->DA0_CONDPG
			ZGS->ZGS_OTPHOR := DA0->DA0_TPHORA
			ZGS->ZGS_OATIVO := DA0->DA0_ATIVO
			ZGS->ZGS_OCODPR := DA1->DA1_CODPRO 
			ZGS->ZGS_OGRUPO := DA1->DA1_GRUPO
			ZGS->ZGS_OPRCVE := DA1->DA1_PRCVEN
			ZGS->ZGS_I_OPRC := DA1->DA1_I_PRCA
			ZGS->ZGS_OPRCMA := DA1->DA1_PRCMAX
			ZGS->ZGS_I_OPRM := DA1->DA1_I_PRMP
			ZGS->ZGS_I_OPTB := DA1->DA1_I_PTBN
			ZGS->ZGS_I_OVII := DA1->DA1_I_VIGI
			ZGS->ZGS_I_OVIF := DA1->DA1_I_VIGF
            ZGS->ZGS_I_PRF1 := DA1->DA1_I_PRF1
            ZGS->ZGS_I_PMF1 := DA1->DA1_I_PMF1 
            ZGS->ZGS_I_PRF2 := DA1->DA1_I_PRF2 
            ZGS->ZGS_I_PMF2 := DA1->DA1_I_PMF2 
            ZGS->ZGS_I_PRF3 := DA1->DA1_I_PRF3 
            ZGS->ZGS_I_PMF3 := DA1->DA1_I_PMF3
            ZGS->ZGS_I_OBS  := DA0->DA0_I_OBS
            ZGS->ZGS_I_PES1 := DA0->DA0_I_PES1
            ZGS->ZGS_I_PES2 := DA0->DA0_I_PES2
            ZGS->ZGS_I_PES3 := DA0->DA0_I_PES3
			ZGS->ZGS_STATUS := "X"
			
			ZGS->(MSUnLock())
			
			RecLock("DA1",.F.)
			DA1->(Dbdelete())
			DA1->(MSUnLock())
			
		Next
	
	Else
	
		Disarmtransaction()
		U_ITMsg("Falha ao excluir tabela de preços","Atenção",,1)
		_lfalha := .T.

	EndIf
	
	If !(_lfalha)

		RecLock("DA0",.F.)
		DA0->(Dbdelete())
		DA0->(MSUnLock())

	EndIf
	
	END TRANSACTION
	
	If !(_lfalha)
		U_ITMsg("Tabela " + ZGS->ZGS_CODTAB + " excluida com sucesso","Atenção",,3)
	EndIf
	
EndIf
	
_lexclui := .F.

Return
