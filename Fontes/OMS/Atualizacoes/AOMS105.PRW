/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor    |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer  | 23/01/2018 | Chamado 23332. Recebimento da data de Entrega.
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer  | 30/01/2018 | Chamado 23296. Tratamento do Status Recepcionado.
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich   | 10/09/2018 | Chamado 26230. Inclusão de campos de tipo de operação e tipo de PV.
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich   | 08/10/2018 | Chamado 26571. Mudança de flag de pallet para S/N.  
 ------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer  | 26/05/2022 | Chamado 39375. Informado uma Data de Canhoto gravar o Status = a "Aprovado" e Dt de Entrega. 
===============================================================================================================================
 Analista      - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração                                                                                 
=====================================================================================================================================================================================================
Antonio Ramos  - Julio Paz    - 07/11/25 - 13/11/25 - 52838   - Alterações no Webservice de Notificação de Canhoto Digitalizado para receber mais um parâmetro informando a origem da digitalização.
=====================================================================================================================================================================================================
*/

#Include 'rwmake.ch' 
#Include "APWEBSRV.CH"
#Include "TOTVS.ch"  
#Include "TBICONN.CH"   

/*
===============================================================================================================================
Programa----------: AOMS105
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2016
===============================================================================================================================
Descrição---------: WebService integração com sistema Estec - Chamado 22908
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS105(__aCookies,__aPostParms,__nProcID,__aProcParms,__cHTTPPage)

Local cHTML        := ''
Local _dDataEnt    := CTOD("")
Local _dAuxDataEnt := CTOD("")
Local _nHifem      := 0
Local _cDepto      := Space(60)

//=====================================================================
// Limpa o ambiente, liberando a licença e fechando as conexões
//=====================================================================
RpcClearEnv() 

//===========================================================================================
// Preparando o ambiente com a filial da carga recebida
//===========================================================================================
PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01'; 
       TABLES "ZGJ","SF2","SA1","SA2","SA4";
       MODULO 'OMS'


Begin Sequence

If Len(__aProcParms) > 3 .And. !Empty(__aProcParms[4,2]) 
   _dAuxDataEnt := __aProcParms[4,2]
   _nHifem      := RAT("-",_dAuxDataEnt)
   //Ex.: 2018-11-2 --> (2) --> 2/11/2018 --> 02/11/02]  //Ex.: 2018-1-23 --> (1) --> 23/1/2018 --> 23/01/23]
   _dAuxDataEnt := SubStr(_dAuxDataEnt,_nHifem+1) +"/"+ SubStr(_dAuxDataEnt,6,(_nHifem-6)) +"/"+ LEFT(_dAuxDataEnt,4)
   _dDataEnt    := CTOD(_dAuxDataEnt)
   U_ITCONOUT("Data de Entrega recebida: "+__aProcParms[4,2]+" -> "+_dAuxDataEnt+" -> "+DToC(_dDataEnt))
EndIf

If Len(__aProcParms) > 4 .And. !Empty(__aProcParms[5,2]) 
   _cDepto := __aProcParms[5,2]
EndIf 

//Verifica se já tem registro no muro
//Se não tem adiciona e retorna status aguardando
DBSelectArea("ZGJ")
ZGJ->(DBSetOrder(1))

If !(ZGJ->(DBSeek(AllTrim(__aProcParms[1,2])+AllTrim(__aProcParms[2,2])+AllTrim(__aProcParms[3,2]))))

	//Verifica se existe a nota na SF2
	If !(SF2->(DBSeek(AllTrim(__aProcParms[1,2])+AllTrim(__aProcParms[2,2])+AllTrim(__aProcParms[3,2]))))
	
		cHTML := '{"status": "Reprovado", '
		cHTML += '"entrega": "N/C", '
		cHTML += '"observacao": "Nota nao localizada no Protheus", '
		cHTML += '"cnpjcli": "N/C", '
		cHTML += '"razaosoc": "N/C", '
		cHTML += '"fantasia": "N/C", '
		cHTML += '"cidade": "N/C", '
		cHTML += '"estado": "N/C", '
		cHTML += '"pedido": "N/C", '
		cHTML += '"carga": "N/C", '
		cHTML += '"transportador": "N/C"}'
		u_itconout("Reprovada digitalizacao do canhoto da nota "+ AllTrim(__aProcParms[1,2]) + "/" +  AllTrim(__aProcParms[2,2]) + " - " +  DToC(_dDataEnt) + " - " +  "Nota nao localizada no Protheus")
		
		Break
	
	EndIf
	
	RecLock("ZGJ",.T.)
	ZGJ->ZGJ_FILIAL:= AllTrim(__aProcParms[1,2])
	ZGJ->ZGJ_NOTA  := AllTrim(__aProcParms[2,2])
	ZGJ->ZGJ_SERIE := AllTrim(__aProcParms[3,2])
  	ZGJ->ZGJ_DTENT := _dDataEnt
	If !Empty(_dDataEnt) //CHAMADO 39375. Quando informado uma Data de Canhoto e existir tabela de Controle de Digitalização de Canhoto (ZGJ) gravar o status da digitalização igual a "Aprovado" e Data de Entrega 
	   ZGJ->ZGJ_STATUS := "Aprovado"
	Else
	   ZGJ->ZGJ_STATUS := "Aguardando Conf"
	EndIf
	ZGJ->ZGJ_DATAI := Date()
	ZGJ->ZGJ_HORAI := Time()
    If ZGJ->(FIELDPOS("ZGJ_USERI")) # 0
	   ZGJ->ZGJ_USERI := "Integrado da Estec"
	EndIf

	If ValType(_cDepto) == "C" 
       ZGJ->ZGJ_ORIGEM := _cDepto
	   If Upper(SubStr(_cDepto,1,3)) == "TR_"
          ZGJ->ZGJ_FISICO := "N"
	   Else 
          ZGJ->ZGJ_FISICO := "S"
	   EndIf 
	EndIf 
	
	ZGJ->(MSUnLock())
	
	cHTML := '{"status": "Aguardando Conf", '
	cHTML += '"entrega": "N/C", '
	cHTML += '"observacao": "N/C", '
	AOMS105R(@cHTML)
	
	U_ITCONOUT("[I] Digitalizado canhoto da nota "+ AllTrim(__aProcParms[1,2]) + "/" +  AllTrim(__aProcParms[2,2]) + " - " +  DToC(_dDataEnt) )
	Break

//Se tem verifica se já foi confirmado e retorna status
Else

	If !SF2->(DBSeek(AllTrim(__aProcParms[1,2])+AllTrim(__aProcParms[2,2])+AllTrim(__aProcParms[3,2])))
	    ZGJ->(RecLock("ZGJ",.F.))
	    ZGJ->ZGJ_OBS:= "Nota nao encontrada: "+AllTrim(__aProcParms[1,2])+" / "+AllTrim(__aProcParms[2,2])+" / "+AllTrim(__aProcParms[3,2])
		ZGJ->(MSUnLock())
	EndIf

	If AllTrim(ZGJ->ZGJ_STATUS) == "Aguardando Conf"
	
		cHTML := '{"status": "Aguardando Conf", '
		cHTML += '"entrega": "N/C", '
		cHTML += '"observacao": "N/C", '
	    AOMS105R(@cHTML)

		u_itconout("[A] Digitalizado canhoto da nota "+ AllTrim(__aProcParms[1,2]) + "/" +  AllTrim(__aProcParms[2,2]) + " - " +  DToC(_dDataEnt))
		Break
				
	ElseIf AllTrim(ZGJ->ZGJ_STATUS) == "Aprovado"
	
		cHTML := '{"status": "Aprovado", '
		cHTML += '"entrega": "' + DToC(ZGJ->ZGJ_DTENT) + '", '
		cHTML += '"observacao": "N/C", '
	    AOMS105R(@cHTML)
		
		u_itconout("Aprovada digitalizacao do canhoto da nota "+ AllTrim(__aProcParms[1,2]) + "/" +  AllTrim(__aProcParms[2,2]) + " - " +  DToC(ZGJ->ZGJ_DTENT)+ " - " +  AllTrim(ZGJ->ZGJ_OBS))
		Break
		
	ElseIf AllTrim(ZGJ->ZGJ_STATUS) == "Reprovado"
	
		cHTML := '{"status": "Reprovado", '
		cHTML += '"entrega": "N/C", '
		cHTML += '"observacao": "' + AllTrim(ZGJ->ZGJ_OBS) + '", '
	    AOMS105R(@cHTML)
		
		u_itconout("Reprovada digitalizacao do canhoto da nota "+ AllTrim(__aProcParms[1,2]) + "/" +  AllTrim(__aProcParms[2,2])+ " - " +  DToC(_dDataEnt)  + " - " +  AllTrim(ZGJ->ZGJ_OBS))
		
		//Apaga registro para se vier nova digitalização fazer nova análise
		ZGJ->(RecLock("ZGJ",.F.))
		ZGJ->(DBDELETE())
		ZGJ->(MSUnLock())

		Break

	ElseIf AllTrim(ZGJ->ZGJ_STATUS) == "Recepcionado"
	
		cHTML := '{"status": "Aguardando Conf", '
		cHTML += '"entrega": "N/C", '
		cHTML += '"observacao": "N/C", '
	    AOMS105R(@cHTML)
		
		U_ITCONOUT("Status Recepcionado alterado p/ Aguardando Conf. Digitalizado canhoto da nota "+ AllTrim(__aProcParms[1,2]) + "/" +  AllTrim(__aProcParms[2,2])+ " - " +  DToC(_dDataEnt)  + " - " +  AllTrim(ZGJ->ZGJ_OBS))
		
		//Apaga registro para se vier nova digitalização fazer nova análise
		ZGJ->(RecLock("ZGJ",.F.))
	    ZGJ->ZGJ_STATUS:= "Aguardando Conf"
		ZGJ->(MSUnLock())

		Break

	EndIf

EndIf

End Sequence

Return(cHTML)

/*
===============================================================================================================================
Programa----------: AOMS105R
Autor-------------: Alex Wallauer
Data da Criacao---: 23/01/2018
===============================================================================================================================
Descrição---------: Grava Resposta
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS105R(cHTML)
		
	SA1->(DBSetOrder(1))
    SA1->(DBSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))
    SC5->(DBSetOrder(1))
    SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))
    SC6->(DBSetOrder(1))
    SC6->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))
    
    If AllTrim(SC6->C6_PRODUTO) == AllTrim(GetMV("IT_CCHEP"))
    
    	_cPallet := "S"
    	
    Else
    
    	_cPallet := "N"
    	
    EndIf

	cHTML += '"cnpjcli": "'       + AllTrim(SA1->A1_CGC) + '", '
	cHTML += '"razaosoc": "'      + SA1->A1_COD + '/' + SA1->A1_LOJA + ' - ' + AllTrim(SA1->A1_NOME) + '", '
	cHTML += '"fantasia": "'      + AllTrim(SA1->A1_NREDUZ) + '", '
	cHTML += '"cidade": "'        + AllTrim(SA1->A1_MUN) + '", '
	cHTML += '"estado": "'        + AllTrim(SA1->A1_EST) + '", '
	cHTML += '"pedido": "'        + AllTrim(SF2->F2_I_PEDID) + '", '
	cHTML += '"carga": "'         + AllTrim(SF2->F2_CARGA) + '", '
	cHTML += '"transportador": "' + AllTrim(SF2->F2_I_NTRAN) + '", '
	cHTML += '"oper_ped": "'      + AllTrim(SC5->C5_I_OPER) + '", '
	cHTML += '"pallet": "'        + _cpallet + '" '
	cHTML += '}'

Return .T.
