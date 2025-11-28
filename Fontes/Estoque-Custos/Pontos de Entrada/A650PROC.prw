/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |07/12/2018| Chamado 27300. Nas OPs automáticas, o CC da OP Pai tem que ser o mesmo p/ todas as OP FIlhas
Alex Wallauer |07/11/2019| Chamado 31126. Correção nas OPs automáticas, o CC de cada OP Pai tem que ser o mesmo p/ todas as OP FIlhas
Alex Wallauer |09/03/2019| Chamado 34943. Correção da SELECT DO SD4 para gravar a descricao de item com mais de um lote
===============================================================================================================================
*/

#Include "TopConn.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A650PROC
Autor-------------: Erich Buttner
Data da Criacao---: 25/09/2013
Descricao---------: Ponto de entrada no MATA650.PRX executado apos o processamento da inclusao da Op e os pedidos de compras.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A650PROC ()

Local _cCentroC:=""

cSc2:= " SELECT C2_NUM cNum, C2_ITEM cIt, C2_SEQUEN cSeq FROM "+RetSqlName("SC2")
cSc2+= " WHERE C2_I_DESC = ' ' AND C2_CC = ' ' "
cSc2+= " AND C2_FILIAL = '"+xFilial("SC2")+"' "
cSc2+= " AND D_E_L_E_T_ = ' ' "

cSc2:= ChangeQuery(cSc2)

//============================================
//Fecha Alias se tiver em uso
//============================================

If Select("TRB") >0
	DBSelectArea("TRB")
	DBCloseArea()
EndIf

//============================================
// Monta Area de Trabalho executando a Query
//============================================
TCQUERY cSc2 New Alias "TRB"
DBSelectArea("TRB")

DBGoTop()

//MsgInfo("1 OP: "+SC2->C2_NUM +" CC: "+ SC2->C2_CC+" SEQ: "+SC2->C2_SEQUEN)	

SC2->(DBSetOrder(1))

//MsgInfo("2 OP: "+SC2->C2_NUM +" CC: "+ SC2->C2_CC+" SEQ: "+SC2->C2_SEQUEN)	
   
While TRB->(!(Eof()))

    If SC2->(DBSeek(xFilial("SC2")+TRB->cNum+TRB->cIt+"001"))
       _cCentroC:=SC2->C2_CC
    EndIf
	
	If SC2->(DBSeek(xFilial("SC2")+TRB->cNum+TRB->cIt+TRB->cSeq))
		SC2->(RecLock("SC2",.F.))
		SC2->C2_I_DESC := GetAdvFVal("SB1","B1_DESC",xFilial("SB1")+SC2->C2_PRODUTO,1,"")
		SC2->C2_CC:=_cCentroC
        SC2->(MSUnLock())
   	EndIf

//     MsgInfo(" OP: "+SC2->C2_NUM +" CC: "+ SC2->C2_CC+" SEQ: "+C2_SEQUEN)	
	
	TRB->(DBSkip())

EndDo

cSd4:= " SELECT D4.R_E_C_N_O_ RECSD4 ,D4_OP cNum, D4_COD COD, B1_DESC DESCR, D4_LOCAL ARM FROM SD4010 D4, SB1010 B1 "
cSd4+= " WHERE D4_I_NPROD = ' '  "
cSd4+= " AND D4_COD = B1_COD "
cSd4+= " AND D4_FILIAL = '"+xFilial("SD4")+"' "
cSd4+= " AND B1_FILIAL = '"+xFilial("SB1")+"' "
cSd4+= " AND D4.D_E_L_E_T_ = ' ' "
cSd4+= " AND B1.D_E_L_E_T_ = ' ' "

cSd4:= ChangeQuery(cSd4)

//============================================
//Fecha Alias se tiver em uso
//============================================
If Select("TRB1") >0
	DBSelectArea("TRB1")
	DBCloseArea()
EndIf

//============================================
// Monta Area de Trabalho executando a Query
//============================================
TCQUERY cSd4 New Alias "TRB1"
DBSelectArea("TRB1")

DBGoTop()

	
While TRB1->(!Eof())

	SD4->(DBGoTo(TRB1->RECSD4))
	SD4->(RecLock("SD4",.F.))
	SD4->D4_I_NPROD := TRB1->DESCR
    SD4->(MSUnLock())
	TRB1->(DBSkip())

EndDo

//============================================
//Fecha Alias se tiver em uso
//============================================
If Select("TRB") >0
	DBSelectArea("TRB")
	DBCloseArea()
EndIf
    

Return 
