/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Lucas Borges  |03/09/2020| Chamado 34024. Incluída gravação da TES para geração de documentos classificados
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT103PN
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/12/2016
Descrição---------: PE na nota fiscal de entrada, após a monstagem do acols e antes da montagem da tela.
					Este ponto de entrada pertence à rotina de manutenção de documentos de entrada, MATA103. 
					Localização: É executada em A103NFISCAL, na inclusão de um documento de entrada. Ela permite ao usuário 
					decidir se a inclusão será executada ou não.
Parametros--------: Nenhum
Retorno-----------: Retorno lógico: .T. = a rotina segue normalmente, .F. = a rotina é cancelada.
===============================================================================================================================
*/  
User Function MT103PN

Local _lRet := .T.
Local _ng
 
Begin Sequence
   //Gatilha campos a partir do pedido ou     
   For _ng := 1 To Len(aCols)
     GATGERAL(_ng) //Chama rotina de gatilho de campos
   Next
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: GATCCPED
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/12/2016
Descrição---------: Gatilho de centro de custo a partir do campo de produto/pedido da nota de entrada
Parametros--------: Nenhum
Retorno-----------: _cCC - centro de custo
===============================================================================================================================
*/  
User Function GATCCPED()

Local _nPosCC	:= 0
Local _cCC 		:= Space(30)

If funname() == "MATA140" .Or. funname() == "MATA103" .Or. funname() == "COMXCOL"
	_nPosCC := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_CC" } )
	If n > 0
		_cCC := acols[n][_nPosCC]
		//Chama rotina de gatilho de campos
		_cCC := GATGERAL(n)
	EndIf
EndIf

Return _cCC

/*
===============================================================================================================================
Programa----------: GATGERAL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/12/2016
Descrição---------: Carga de gatilhos de campos no acols do mata103
Parametros--------: Nenhum
Retorno-----------: _cCC - centro de custo
===============================================================================================================================
*/  
Static Function GATGERAL(_nI)

Local _nPosTes, _nPosCC, _nPosPedido,_nPosItem, _nPosProd 
Local _cChaveSC7, _cCCusto, _cChaveSB1, _cChaveZFX
Local _aAreaSC7   := SC7->(GetArea())
Local _aAreaSB1   := SB1->(GetArea())
Private _cRet_TN := U_PosPedFaT(  cA100For+cLoja  ,  CNFISCAL+CSERIE  ) //Define se é pedido troca nota


SC7->(DBSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN
SB1->(DBSetOrder(1)) // B1_FILIAL+B1_COD    
ZFX->(DBSetOrder(1)) // ZFX_FILIAL+ZFX_PRODUT+ZFX_CCUSTO  
   
_nPosTes    := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_TES" } )
_nPosCC     := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_CC" } )
_nPosPedido := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_PEDIDO" } )
_nPosItem   := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_ITEMPC" } )
_nPosProd   := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_COD" } )
_nPosoPER   := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_OPER" } )
_nPosCLAS   := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_CLASFIS" } )
_nPosLOCA   := aScan( aHeader , {|x| Upper( AllTrim(x[2]) ) == "D1_LOCAL" } )

Begin Sequence
   _cCCusto := ""
   _cChaveSC7 := ""
   _cChaveSB1 := ""
   _cChaveZFX := ""

   If ! Empty(aCols[_nI,_nPosPedido])
      _cChaveSC7 := xFilial("SC7") + aCols[_nI,_nPosPedido] + aCols[_nI,_nPosItem]
   EndIf

   If ! Empty(aCols[_nI,_nPosProd])
      _cChaveSB1 := xFilial("SB1") + aCols[_nI,_nPosProd] 
      _cChaveZFX := xFilial("ZFX") + aCols[_nI,_nPosProd] 
   Else
      Break
   EndIf

   _cChaveFOR := xFilial("ZFX") + CA100FOR + CLOJA

   //==============================================================
   // Localiza centro de custo no item do Pedido de Compras     
   //==============================================================
   If !Empty(_cChaveSC7) .And. SC7->(DBSeek(_cChaveSC7)) .And. ! Empty(SC7->C7_CC)
      _cCCusto := SC7->C7_CC
   EndIf

   //==============================================================
   // Localiza centro de custo no Cadastro de Produtos.
   //==============================================================
   If Empty(_cCCusto) .And. !Empty(_cChaveSB1) .And. SB1->(DBSeek(_cChaveSB1))
      _cCCusto := SB1->B1_CC
   EndIf

   //==============================================================
   // Localiza centro de custo novo cadastro de amarração 
   // Filial x Produto x Centro de Custo
   //==============================================================   
   ZFX->(DBSetOrder(1))
   If Empty(_cCCusto) .And. !Empty(_cChaveZFX) .And. ZFX->(DBSeek(_cChaveZFX))    
      _cCCusto := ZFX->ZFX_CCUSTO
   EndIf

   //==============================================================
   // Localiza centro de custo novo cadastro de amarração 
   // Filial x Fornecedor x Centro de Custo
   //==============================================================     
   ZFX->(DBSetOrder(3))
   If Empty(_cCCusto) .And. !Empty(_cChaveFOR) .And. ZFX->(DBSeek(_cChaveFOR))
      _cCCusto := ZFX->ZFX_CCUSTO
   EndIf

   //==========================================================
   // Atualiza o centro de custo do item da nota de entrada.
   //==========================================================
   If ! Empty(_cCCusto) .And. Empty(aCols[_nI,_nPosCC])
      aCols[_nI,_nPosCC] := _cCCusto
   EndIf

   //==========================================================
   //Atualiza campos se For troca nota
   //==========================================================
   If _cRet_TN == "ACHOU_PF"
      n := _nI

      If SB1->B1_GRUPO == '0813' //É Pallet
         //Campo D1_TES, gatilhos e validações
         If _nPosTES > 0
            aCols[_nI,_nPosTES] := MaTesInt(1,'03',cA100For,cLoja,If(cTipo$"DB","C","F"),SB1->B1_COD,"D1_TES")  
            MaAvalTes("E",aCols[_nI,_nPosTES])
            MaFisRef("IT_TES","MT100",aCols[_nI,_nPosTES]) 
         EndIf
         //Campo D1_CLASFIS, gatilhos e validações
         If _nPosTES > 0
            aCols[_nI,_nPosCLAS] := Subs(SB1->B1_ORIGEM,1,1)+Posicione("SF4",1,xFilial()+SB1->B1_TE,'F4_SITTRIB')
            MAFISREF("IT_CLASFIS","MT100",aCols[_nI,_nPosCLAS]) 
         EndIf
         //Campo D1_CC, gatilhos e validações
       	If _nPosCC > 0 .And. Empty(aCols[_nI,_nPosCC])                                                                                       
            aCols[_nI,_nPosCC] := SuperGetMV("IT_CCTRCNP",.F.," ")
         EndIf
         //Campo D1_OPER, gatilhos e validações
         If _nPosoPER > 0
            aCols[_nI,_nPosoPER] := '03'
            MTA103TROP(_nI)
         EndIf
         //Campo D1_LOCAL, gatilhos e validações                                                                        
         If _nPosLOCA > 0
            aCols[_nI,_nPosLOCA] := '40'
         EndIf
      Else //Não é pallet
         //Campo D1_TES, gatilhos e validações
         If _nPosTES > 0
            aCols[_nI,_nPosTES] := MaTesInt(1,'03',cA100For,cLoja,If(cTipo$"DB","C","F"),SB1->B1_COD,"D1_TES")  
            MaAvalTes("E",aCols[_nI,_nPosTES])
            MaFisRef("IT_TES","MT100",aCols[_nI,_nPosTES])
         EndIf
         //Campo D1_CLASFIS, gatilhos e validações                                                             
       	If _nPosCLAS > 0
            aCols[_nI,_nPosCLAS] := Subs(SB1->B1_ORIGEM,1,1)+Posicione("SF4",1,xFilial()+SB1->B1_TE,'F4_SITTRIB')
            MAFISREF("IT_CLASFIS","MT100",aCols[_nI,_nPosCLAS]) 
         EndIf
         //Campo D1_CC, gatilhos e validações
         If _nPosCC > 0 .And. Empty(aCols[_nI,_nPosCC])                                                                                     
            aCols[_nI,_nPosCC] := SuperGetMV("IT_CCTRCNF",.F.,"  ")
         EndIf
         //Campo D1_OPER, gatilhos e validações
         If _nPosoPER > 0
            aCols[_nI,_nPosoPER] := '03'
            MTA103TROP(_nI)
         EndIf
         //Campo D1_LOCAL, gatilhos e validações
         If _nPosLOCA > 0
            aCols[_nI,_nPosLOCA] := '40'
         EndIf
      EndIf
   EndIf

End Sequence

FWRestArea(_aAreaSC7)
FWRestArea(_aAreaSB1)

Return aCols[_nI,_nPosCC]
