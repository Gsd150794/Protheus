/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |08/02/2023| Chamado 42719. Acrescentada a opcao NF no campo C7_I_URGEN : S(SIM), N(NAO) F(NF).
Alex Wallauer |15/07/2023| Chamado 47732. Ajuste do tamanho do titulo "Compra Direta" na tela via Web.
Alex Wallauer |05/09/2025| Chamado 51839. Ajustes dos campos custumizados da capa para o tema Dark.
================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120TEL
Autor-------------: Talita Teixeira
Data da Criacao---: 31/01/2013
Descrição---------: Rotina responsavel pela inclusão do campo aplicação no cabeçalho do pedido de compra. 
					Localização: Function A120PEDIDO - Função do Pedido de Compras responsavel pela inclusão, alteração, exclusão
					e cópia dos PCs.
					Em que Ponto: Se encontra dentro da rotina que monta a dialog do pedido de compras antes  da montagem dos 
					folders e da chamada da getdados.
Parametros--------: ParamIXB[1] -> O -> Objeto da dialog do Pedido de Compras
                    ParamIXB[2] -> A -> Array contendo a posição dos gets do Pedido de Compras
                    ParamIXB[3] -> A -> Array contendo os objetos relacionado aos campos dos folders do Pedido de Compras
                    ParamIXB[4] -> N -> Opção selecionada no Pedido de Compras (inclusão, alteração, exclusão, etc.)
                    ParamIXB[5] -> N -> Número do RECNO do registro do Pedido de Compras selecionado
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT120TEL

Local aArea		:= FWGetArea()  
Local oNewDialog:= ParamIXB[1]
Local aPosGet	:= ParamIXB[2]
Local nOpcx		:= ParamIXB[4]
Local _nLinA    := 62
Local _nLinB    := 73
Local _nLinC    := 51  , _nX
Local nPosPreco := aScan(aHeader,{|x|AllTrim(x[2])=="C7_PRECO"})  
Local _nC7PRURS := aScan(aHeader,{|x|AllTrim(x[2])=="C7_I_PRURS"})
Local _nC7PRTRS := aScan(aHeader,{|x|AllTrim(x[2])=="C7_I_PRTRS"})
Local _nC7TOTAL := aScan(aHeader,{|x|AllTrim(x[2])=="C7_TOTAL"})
Local nPProduto := aScan(aHeader,{|x|AllTrim(x[2])=="C7_PRODUTO"})
Local nPosTabPre:= aScan(aHeader,{|x|AllTrim(x[2])=="C7_CODTAB"})  

Public cClaim	    := "2"//CLAIM
Public cAplic		:= ""
Public cUrgen		:= " "
Public cCompD		:= " "
Public cCInve		:= Space(TamSX3("C7_I_CDINV")[1])
Public cDsInv		:= Space(TamSX3("C7_I_DSINV")[1])
Public lSolic		:= .F.

If lCop // lCop é Private DA lCopia que indica que é copia 
   AIB->(DBSetOrder(1))//AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB_CODTAB+AIB_ITEM
   AIA->(DBSetOrder(1))//AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIA_CODTAB
   For _nX := 1 To Len( aCols )
      aCols[_nX][nPosTabPre] := Space(Len(AIB->AIB_CODTAB))
      
      If AIA->(DBSeek(xFilial("AIA")+CA120FORN+CA120LOJ)) 
         While AIA->(!Eof()) .And. xFilial("AIA")+CA120FORN+CA120LOJ == AIA->(AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR)
            If AIA->AIA_DATDE <= Date() .And.  AIA->AIA_DATATE >= Date() .And. AIA->AIA_I_SITW = "A"//DENTRO DA VIGENCIA E APROVADA
               If AIB->(DBSeek(xFilial("AIB")+CA120FORN+CA120LOJ+AIA->AIA_CODTAB))    
                  While AIB->(!Eof()) .And. xFilial("AIB")+CA120FORN+CA120LOJ+AIA->AIA_CODTAB == AIB->(AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB->AIB_CODTAB)
                        If aCols[_nX][nPProduto ] == AIB->AIB_CODPRO .And. AIB->AIB_MOEDA = nMoedaPed
                           aCols[_nX][nPosTabPre] := AIB->AIB_CODTAB
                           Exit
                        EndIf
                        AIB->(DBSkip())
                  EndDo
                  If !Empty(aCols[_nX][nPosTabPre]) 
                     If !Empty(AIA->AIA_CONDPG) .And. AIA->AIA_CONDPG <> cCondicao
                        cCondicao:= AIA->AIA_CONDPG// cCondicao VARIAVEL Private DA TELA PADRÃO DO PC
                     EndIf
                     If !Empty(AIA->AIA_I_TPFR) .And. AIA->AIA_I_TPFR <> LEFT(cTpFrete,1)
                        cTpFrete :=RetTipoFrete(AIA->AIA_I_TPFR)
                     EndIf
                     Exit
                  EndIf           
               EndIf
            EndIf
            AIA->(DBSkip())
         EndDo
      EndIf
   Next
EndIf

If nOpcx <> 3
   cClaim	:= SC7->C7_I_CLAIM//CLAIM
   cAplic	:= SC7->C7_I_APLIC
   cUrgen	:= SC7->C7_I_URGEN
   cCInve	:= SC7->C7_I_CDINV
   cDsInv	:= Posicione("ZZI",1,xFilial("ZZI") + SC7->C7_I_CDINV, "ZZI_DESINV")
   cCompD	:= SC7->C7_I_CMPDI
EndIf           
If Empty(cClaim) .Or. cA120Forn <> "F00004"
   cClaim:= "2"
EndIf

//Posição referente a CLAIM
If SC7->(FIELDPOS("C7_I_CLAIM")) <> 0 
   @ _nLinC  , aPosGet[1,12]+10 Say 'CLAIM' PIXEL SIZE 28,9 Of oNewDialog
   @ _nLinC-1, aPosGet[1,07]+15 MSCOMBOBOX cClaim ITEMS {"1=Sim","2=Não"} SIZE 036, 010 OF oNewDialog PIXEL Valid {|| Pertence('12')}  WHEN (IF(cA120Forn<>"F00004",cClaim:="2",),(cA120Forn="F00004"))
EndIf
//Posição referente a aplicação
@ _nLinA, aPosGet[1,5]-12	Say 'Aplicação' PIXEL SIZE 28,9 Of oNewDialog 
@ _nLinA, aPosGet[1,6]-25	MSCOMBOBOX oAplic VAR cAplic ITEMS {"C=Consumo","I=Investimento","M=Manutenção","S=Serviço"} SIZE 072, 010 OF oNewDialog PIXEL Valid {|| U_VldInf("P"), Pertence('CIMS')} WHEN MT120Vld()

//Posição referente ao Código de Investimento
@ _nLinB, aPosGet[1,1] 		Say 'Código Projeto' PIXEL SIZE 60,9 Of oNewDialog  
@ _nLinB, aPosGet[1,2] 		MSGET cCInve F3 'ZZI_P' PIXEL SIZE 10,08 Of oNewDialog WHEN MT120Vld("PROJETO") Valid {|| U_VldInf("I")}  
@ _nLinB, aPosGet[1,2]+50	MSGET cDsInv PIXEL SIZE 80,08 Of oNewDialog WHEN .F.

//Posição referente ao Compra Direta
@ _nLinB, aPosGet[1,3]		Say 'Compra Direta' PIXEL SIZE 60,9 Of oNewDialog 
@ _nLinB, aPosGet[1,4]		MSCOMBOBOX oCompD VAR cCompD ITEMS {"","S=Sim","N=Não","O=Outros"} SIZE 072, 010 OF oNewDialog PIXEL Valid {|| MT120Vld("COMPRA_DIRETA")  }

//Posição referente ao Urgente
@ _nLinB, aPosGet[1,5]-12	Say 'Urgente' PIXEL SIZE 28,9 Of oNewDialog 
@ _nLinB, aPosGet[1,6]-25	MSCOMBOBOX oUrgen VAR cUrgen ITEMS {"","S=Sim","N=Não","F=NF"} SIZE 072, 010 OF oNewDialog PIXEL Valid {|| MT120Vld("URGENTE")  } WHEN MT120Vld()  

nSalva:=n
If _nC7PRURS <> 0 .And. nPosPreco <> 0 .And. _nC7PRTRS <> 0 .And. _nC7TOTAL <> 0
   For _nX := 1 To Len( aCols )
      n:=_nX 
      aCols[n,_nC7PRURS]:=aCols[n,nPosPreco]*nTxMoeda
      aCols[n,_nC7PRTRS]:=aCols[n,_nC7TOTAL]*nTxMoeda
   Next
EndIf

If lCop // lCop é Private DA lCopia que indica que é copia 
   nPosQt      := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_QUANT"})
   nPosQtOri   := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_I_QTORI"})
   nPosMELT    := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_I_MEAGE"})
   For _nX := 1 To Len( aCols )
      aCols[_nX,nPosQtOri]:=aCols[_nX,nPosQt]
      aCols[_nX,nPosMELT ]:=" "
   Next
EndIf
n:=nSalva

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: MT120Vld
Autor-------------: Alex Wallauer
Data da Criacao---: 16/12/2019
Descrição---------: Validações e edições de campor custumizados
Parametros--------: cCampo: Origem
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MT120Vld(cCampo)

Local lRet := .T. , _nX
Local _nPosCdInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_CDINV"})
Local _nPosDsInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_DSINV"})
Local _nPosCdSInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_SUBIN"})
Local _nPosDsSInv	:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_SUIND"})

If cCampo = NIL
   If INCLUI
   	If lSolic
   		lRet := .F.
   	EndIf
   ElseIf ALTERA
   	If !Empty(SC7->C7_NUMSC)
   		lRet := .F.
   	EndIf
   EndIf
EndIf

If cCampo = "PROJETO" .And. lRet
   If LEFT(cAplic,1) <> "I"
      cCInve:= Space(TamSX3("C7_I_CDINV")[1])
      cDsInv:= Space(TamSX3("C7_I_DSINV")[1])      
      For _nX := 1 To Len( aCols )
          aCols[_nX,_nPosCdInv ]:=cCInve
          aCols[_nX,_nPosDsInv ]:=cDsInv
          aCols[_nX,_nPosCdSInv]:=cCInve
          aCols[_nX,_nPosDsSInv]:=cDsInv
      Next
		lRet := .F.
   EndIf
EndIf

If cCampo = "COMPRA_DIRETA" .And. lRet
   If cCompD = "S"
      cUrgen:="S"
   EndIf
EndIf

If cCampo = "URGENTE" .And. lRet
   If cCompD = "S" .And. cUrgen <> "S"
      U_ITMsg("Campo urgente dever esta igual a SIM quando For compra direta igual a SIM",'Atenção!',,1)
      lRet := .F.   
   EndIf
EndIf

Return(lRet)
