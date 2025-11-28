/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |27/02/2025| Chamado 49391. Desenvolvimento de Rotina para alteração da Data de Entrega do Pedido de Compras.
===============================================================================================================================
*/

#Include "TOTVS.ch"

#define	MB_OK			0
#define MB_ICONASTERISK	64

/*
===============================================================================================================================
Programa----------: ACOM042  
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/02/2025
Descrição---------: Rotina para alteração de data de entrega do pedido de compras.
                    Versão do Fonte ACOM008 (Alteração da Data de Faturamento) adaptado para alteração da data de entrega 
					     do Pedido de Compras. Chamado 49391.
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function ACOM042

Local aArea			:= FWGetArea()
Local cGet1			:= SToD("//")
Local _cMotivo   	:= Space(Len(ZY1->ZY1_COMENT))
Local nX			:= 0
Local _cQry			:= ""
Local _cAliasQry    := GetNextAlias()
Local aHeader		:= {}
Local aCols			:= {}
Local aRecnos		:= {}
Local aFields		:= {"C7_NUM","C7_TIPO","C7_ITEM","C7_DATPRF","C7_PRODUTO","C7_DESCRI","A2_NOME"}
Local aAlterFields	:= {}
Local nOpc			:= 0
Local _cCampoSX3
Local oGet1
Local oSayNDF
Local oSButton1
Local oSButton2
Local oDlg
Local _aCabec := {}
Local _aLinha := {}
Local _aItens := {}

Private oMSNewSC7
Private lMsErroAuto := .F.

Begin Sequence 
   SY1->(DBSetOrder(3)) // Y1_FILIAL + Y1_USER
   
   If SY1->(MsSeek(xFilial("SY1") + __cUserId))
	  //Montagem do aheader
	  aHeader := {}
	  aCols   := {}
	  For nX := 1 To Len(aFields)
	      _cCampoSX3 := aFields[nX]
		  aAdd( aHeader , {   Getsx3cache(_cCampoSX3,"X3_TITULO")  ,;
		  Getsx3cache(_cCampoSX3,"X3_CAMPO")   ,;
		  Getsx3cache(_cCampoSX3,"X3_PICTURE") ,;
		  Getsx3cache(_cCampoSX3,"X3_TAMANHO") ,;
		  Getsx3cache(_cCampoSX3,"X3_DECIMAL") ,;
		  Getsx3cache(_cCampoSX3,"X3_VALID")   ,;
		  Getsx3cache(_cCampoSX3,"X3_USADO")   ,;
		  Getsx3cache(_cCampoSX3,"X3_TIPO")    ,;
		  Getsx3cache(_cCampoSX3,"X3_F3")      ,;
		  Getsx3cache(_cCampoSX3,"X3_CONTEXT")  })
	  Next
   EndIf
	
   // Somente sao selecionados itens que nao possuem restricoes
   _cQry := " SELECT C7_NUM,C7_TIPO,C7_ITEM,C7_PRODUTO,C7_DESCRI,C7_DATPRF,C7_FORNECE,C7_LOJA,SC7.R_E_C_N_O_ AS RECSC7,A2_NOME "
   _cQry += " FROM " + RetSqlName("SC7") + " SC7 "
   _cQry += " INNER JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
   _cQry += " WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
   _cQry += "  AND C7_NUM = '" + SC7->C7_NUM + "' "
   _cQry += "  AND ((C7_QUJE < C7_QUANT "
   _cQry += "  OR C7_QTDACLA > 0 ) "
   _cQry += "  AND C7_RESIDUO <> 'S') "
   _cQry += "  AND SC7.D_E_L_E_T_ = ' ' "
	
   MPSysOpenQuery( _cQry , _cAliasQry )
   DBSelectArea(_cAliasQry)

   (_cAliasQry)->( DBGoTop() )
	
   If ! (_cAliasQry)->(Eof())
      While (_cAliasQry)->(!Eof())
	      aAdd(aCols,		{(_cAliasQry)->C7_NUM, (_cAliasQry)->C7_TIPO, (_cAliasQry)->C7_ITEM, SToD((_cAliasQry)->C7_DATPRF), (_cAliasQry)->C7_PRODUTO, (_cAliasQry)->C7_DESCRI,  (_cAliasQry)->A2_NOME,.F.})
	      aAdd(aRecnos,	(_cAliasQry)->RECSC7)
		   (_cAliasQry)->(DBSkip())
	   EndDo
			
	   DEFINE MSDIALOG oDlg TITLE "Pedido de Compra - Alt.Dt.Entrega.PC" FROM 000, 000  TO 300, 700 COLORS 0, 16777215 PIXEL
			
	      oMSNewSC7 := MsNewGetDados():New( 001, 002, 101, 348, , "AllwaysTrue", "AllwaysTrue", "", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeader, aCols)
	      @ 109, 002 Say oSayNDF PROMPT "Nova Data Entrega: " SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
	      @ 107, 064 MSGET oGet1 VAR cGet1 SIZE 055, 010 OF oDlg VALID U_VLDDTFAT(cGet1,2,aRecnos) COLORS 0, 16777215 PIXEL
			
	      @ 109, 125 Say "Comentario:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
	      @ 107, 155 MSGET _cMotivo    SIZE 190, 010 OF oDlg COLORS 0, 16777215 PIXEL
			
	      DEFINE SBUTTON oSButton1 FROM 129, 142 Type 01 OF oDlg ENABLE ACTION (If(VLDUSER(cGet1),(nOpc:=1, oDlg:End()),))
	      DEFINE SBUTTON oSButton2 FROM 129, 175 Type 02 OF oDlg ENABLE ACTION (nOpc := 0, oDlg:End())
			
      ACTIVATE MSDIALOG oDlg CENTERED

	   If nOpc == 1
		   If U_VLDDTFAT(cGet1,2,aRecnos)
		      _dDataOld := CTOD("  /  /  ")

             For nX := 1 To Len(aRecnos)
			       SC7->(DBGoTo(aRecnos[nX]))
			       _dDataOld := SC7->C7_DATPRF
			       
                If nX == 1
                   //======================================================================
                   // Inicializa variáveis utilizadas pelo MSEXECAUTO()
                   //======================================================================
                   cClaim   := SC7->C7_I_CLAIM //CLAIM
                   cAplic   := SC7->C7_I_APLIC
                   cUrgen   := SC7->C7_I_URGEN
                   cCInve   := SC7->C7_I_CDINV
                   cDsInv   := Posicione("ZZI",1,xFilial("ZZI") + SC7->C7_I_CDINV, "ZZI_DESINV")
                   cCompD   := SC7->C7_I_CMPDI
                   lSolic   := .F.

                   //======================================================================
                   // Monta o Array de Cabeçalho do MSEXECAUTO()
                   //======================================================================
                   aAdd(_aCabec,{"C7_NUM"     ,SC7->C7_NUM})
                   aAdd(_aCabec,{"C7_EMISSAO" ,SC7->C7_EMISSAO})
                   aAdd(_aCabec,{"C7_FORNECE" ,SC7->C7_FORNECE})
                   aAdd(_aCabec,{"C7_LOJA"    ,SC7->C7_FORNECE})
                   aAdd(_aCabec,{"C7_COND"    ,SC7->C7_COND}) 
                   aAdd(_aCabec,{"C7_CONTATO" ,SC7->C7_CONTATO})
                   aAdd(_aCabec,{"C7_FILENT"  ,SC7->C7_FILENT})
                EndIf 
                
                _aLinha := {}
                aAdd(_aLinha,{"C7_ITEM"    ,SC7->C7_ITEM    ,Nil})
                aAdd(_aLinha,{"C7_PRODUTO" ,SC7->C7_PRODUTO ,Nil})
                aAdd(_aLinha,{"C7_QUANT"   ,SC7->C7_QUANT   ,Nil})
                aAdd(_aLinha,{"C7_PRECO"   ,SC7->C7_PRECO   ,Nil})
                aAdd(_aLinha,{"C7_TOTAL"   ,SC7->C7_TOTAL   ,Nil})
                aAdd(_aLinha,{"C7_DATPRF"  ,cGet1           ,Nil}) // Data de Entrega.
                aAdd(_aLinha,{"LINPOS"     ,"C7_ITEM"       ,SC7->C7_ITEM})
                aAdd(_aLinha,{"AUTDELETA"  ,"N" ,Nil})
                aAdd(_aItens,_aLinha)

		      Next nX

            lMsErroAuto := .F.

            MSExecAuto({|a,b,c,d,e,f,g,h| MATA120(a,b,c,d,e,f,g,h)},1,_aCabec,_aItens,4)
            
            If !lMsErroAuto
               ACOM42Moni(_dDataOld,_cMotivo)

               U_ITMsg("Data de Entrega do Pedido de Compras alterada de " + DToC(_dDataOld) + " para " + DToC(cGet1) +" com sucesso.","Atenção",,2)
            Else
               U_ITMsg("Não foi possível alterar a data de entrega. Erro na gravação da alteração da Data de Entrega.","Atenção","",1)
               MostraErro()
            EndIf
            
		   EndIf
      Else
         U_ITMsg("Alteração da Data de Entrega cancelada pelo Usuário.","Atenção","",1)
      EndIf
	
      DBSelectArea(_cAliasQry)
      (_cAliasQry)->( DBCloseArea() )
   Else
      U_ITMsg("Não é permitido alterar data de entrega de pedidos de compra já encerrados.","Usuário Inválido","",1)
   EndIf
      
   //======================================================================
   // Grava log da alteração de data de faturamento por pedido de compras 
   //====================================================================== 
   U_ITLOGACS('ACOM042')

End Sequence 

FWRestArea(aArea)

Return    

/*
===============================================================================================================================
Programa----------: ACOM42Moni()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/02/2025
Descrição---------: Rotina que atualiza a ZY1 do monitor
Parametros--------: _dDataOld = dt anterior
                    _cMotivo  = Motivo da Alteração
Retorno-----------: Nenhum 
===============================================================================================================================
*/
Static Function ACOM42Moni(_dDataOld,_cMotivo)

Local aRecnos2 := {} 
Local nX
Local _cTRBZY1 := GetNextAlias()
Local _cQryZY1

Begin Sequence 
   _cQryZY1 := "SELECT R_E_C_N_O_ ZY1_REC , ZY1_SEQUEN "
   _cQryZY1 += "FROM " + RetSqlName("ZY1") + " "
   _cQryZY1 += "WHERE ZY1_FILIAL = '" + SC7->C7_FILIAL + "' "
   _cQryZY1 += "  AND ZY1_NUMPC = '" + SC7->C7_NUM + "' "
   _cQryZY1 += "  AND D_E_L_E_T_ = ' ' "
	
   MPSysOpenQuery(_cQryZY1 , _cTRBZY1 )
	
   (_CTRBZY1)->(DBGoTop())
   _cSeque:="0"

   If !(_CTRBZY1)->(Eof()) .And. !Empty((_CTRBZY1)->ZY1_SEQUEN)

      While (_CTRBZY1)->(!Eof())
         aAdd(aRecnos2, (_CTRBZY1)->ZY1_REC )
         If Val((_CTRBZY1)->ZY1_SEQUEN) > Val(_cSeque)
            _cSeque := (_CTRBZY1)->ZY1_SEQUEN
         EndIf 
         (_CTRBZY1)->(DBSkip())
      EndDo
      _cSeque := Soma1(_cSeque)
   Else
      _cSeque := StrZero(1,Len(ZY1->ZY1_SEQUEN)) 
   EndIf    

   (_CTRBZY1)->(DBCloseArea())
   DBSelectArea("SC7")

   ZY1->(RecLock("ZY1", .T.))
   ZY1->ZY1_FILIAL	:= SC7->C7_FILIAL
   ZY1->ZY1_NUMPC	:= SC7->C7_NUM
   ZY1->ZY1_SEQUEN	:= _cSeque
   ZY1->ZY1_DTMONI	:= Date()
   ZY1->ZY1_HRMONI	:= Time()
   If Empty(_cMotivo)
      ZY1->ZY1_COMENT:="Data de entrega do pedido de compras alterada de " + DToC(_dDataOld) + " para " + DToC(SC7->C7_DATPRF)
   Else
      ZY1->ZY1_COMENT:=_cMotivo
   EndIf
   ZY1->ZY1_CODUSR	:= __cUserId
   ZY1->ZY1_NOMUSR	:= UsrFullName(__cUserId)
   ZY1->ZY1_DTNECE := SC7->C7_DATPRF
   ZY1->ZY1_DTFAT  := SC7->C7_I_DTFAT
   ZY1->(MSUnLock())

   For nX := 1 To Len(aRecnos2)
       ZY1->(DBGoTo(aRecnos2[nX]))
       ZY1->(RecLock("ZY1", .F.))
       //ZY1->ZY1_DTFAT:= SC7->C7_DATPRF 
	    ZY1->ZY1_DTNECE := SC7->C7_DATPRF
       ZY1->(MSUnLock())
   Next nX

End Sequence 

Return  
