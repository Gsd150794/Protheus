/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |16/07/2025| Chamado 50214. Correção no nome da variável utilizada para posicionar a data de faturamento alterada
Julio Paz     |16/07/2025| Chamado 51398. Correção de Error log. Declaração de variável como Private para ser utilizada e objeto de tela
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA120BUT
Autor-------------: Xavier
Data da Criacao---: 15/04/2015
Descrição---------: Ponto de entrada criação de botões no pedido de compras
					Localização: Function A120PEDIDO - Função do Pedido de Compras e Autorização de Entrega responsavel pela 
					inclusão, alteração, exclusão e cópia dos PCs. 
					Em que Ponto: No inico da Função, antes de&nbsp;montar a&nbsp;ToolBar do Pedido de Compras, deve ser usado
					para adicionar botões do usuario na toolbar do PC ou AE através do retorno de um Array com a estrutura do 
					botão a adicionar.
Parametros--------: Nenhum
Retorno-----------: AButtUser -> A -> O retorno deve ser um array onde cada elemento deve ser um subarray com a	seguinte estrutura:
					{ "BITMAP", { || Funcao() }, "ToolTip" }
					Onde:
					"BITMAP" -> Nome do bitmap do botao. O mesmo deve estar contido nas DLLs de recursos do siga.
					{ || Funcao() } -> CodeBlock contendo a funcao a ser chamada. Esta funcao pode ser um ExecBlock
					"ToolTip" -> Descricao do Botao.
===============================================================================================================================
*/
User Function MA120BUT

Local aUsrBt := {}

aAdd(aUsrBt,{'',{|| U_GDTotSB2(GdFieldGet("C7_PRODUTO"))},"Consultar saldo atual"  ,"Consultar saldo atual"  })  
aAdd(aUsrBt,{'',{|| U_CCOM002(2)                        },"Titulos previstos    "  ,"Titulos previstos"      }) 
aAdd(aUsrBt,{"",{|| U_AGLT0192(.F.)                     },"Agendamento Entrega LT" ,"Agendamento Entrega LT" }) 
aAdd(aUsrBt,{"",{|| U_MT120DtFat()                      },"Altera Data Faturamento","Altera Data Faturamento"})  
aAdd(aUsrBt,{"",{|| U_MT120DtEnt()                      },"Altera Data de Entrega" ,"Altera Data de Entrega"})  

Return aUsrBt

/*
===============================================================================================================================
Programa----------: MT120DtFat  
Autor-------------: Alex Walaluer
Data da Criacao---: 01/06/2023
Descrição---------: Rotina para alteração de data de faturamento dos itens do pedido de compras
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function MT120DtFat

Local aArea			:= FWGetArea()
Local _dDtFatNew	:= CTOD("")
Local _dDtFatOld    := CTOD("")
Local _nI2			:= 0
Local nOpc			:= 0
Local nColItem := aScan(aHeader,{|x|AllTrim(x[2])=="C7_ITEM"})
Local nColDtFat:= aScan(aHeader,{|x|AllTrim(x[2])=="C7_I_DTFAT"})
Local nColProd := aScan(aHeader,{|x|AllTrim(x[2])=="C7_PRODUTO"})
Local nColDescr:= aScan(aHeader,{|x|AllTrim(x[2])=="C7_DESCRI"})
Local _bHeadClk := {|oObj,nCol| ITOrdLbx( oObj , nCol) }
Local _bDblClk  := {|         | ITDblClk( @_oLbxAux   ) }
Local _nDtLimFt	:= SuperGetMV("IT_DTLIMFT",.F.,180)	// Limite de dias para data de Faturamento
Local _dLimFt	:= Date() + _nDtLimFt			// Data limite maximo para data de Faturamento
Local _dLimAnt	:= Date() - _nDtLimFt			// Data limite minimo para data de Faturamento
Local oOk		:= LoadBitmap( GetResources() , "LBOK" )
Local oNo		:= LoadBitmap( GetResources() , "LBNO" )

Local oGet1
Local oSayNDF
Local oSButton1
Local oSButton2
Local oDlg
Local _aBrowse :={}

Private nITPosAnt := 0

_aCab:={}
aAdd(_aCab,"")
aAdd(_aCab,aHeader[nColItem ,1])
aAdd(_aCab,aHeader[nColDtFat,1])
aAdd(_aCab,aHeader[nColProd ,1])
aAdd(_aCab,aHeader[nColDescr,1])
aAdd(_aCab,"Linha")

For _nI2 := 1 To Len( acols )
    If aTail(aCols[_nI2]) // Se Linha Deletada
       Loop
    EndIf
    _aItensB:={}
    aAdd(_aItensB,.T.)                   //01
    aAdd(_aItensB,ACOLS[_nI2][nColItem ])//02
    aAdd(_aItensB,ACOLS[_nI2][nColDtFat])//03
    aAdd(_aItensB,ACOLS[_nI2][nColProd ])//04
    aAdd(_aItensB,ACOLS[_nI2][nColDescr])//05
    aAdd(_aItensB,_nI2)                  //06
    aAdd(_aBrowse,_aItensB)                    

	If Empty(_dDtFatOld) .And. !Empty(ACOLS[_nI2][nColDtFat])
	   _dDtFatOld:=ACOLS[_nI2][nColDtFat]
	EndIf
Next

_dDtFatNew:=_dDtFatOld
nITPosAnt:= 0

While .T.

   DEFINE MSDIALOG oDlg TITLE "Altera da Data de Faturamento em massa" FROM 000, 000  TO 300, 700 COLORS 0, 16777215 PIXEL
			
	@ 001,002 LISTBOX _oLbxAux FIELDS TITLE "" SIZE 348,101, PIXEL ; // 001, 002, 101, 348,
										ON		DblClick( Eval(_bDblClk,_oLbxAux) )	

	_oLbxAux:SetArray( _aBrowse )
	_oLbxAux:bLine       := {|| { If( _aBrowse[ _oLbxAux:nAT][1] , oOk , oNo ) ,;
	                                  _aBrowse[ _oLbxAux:nAT][2],;
									  _aBrowse[ _oLbxAux:nAT][3],;
									  _aBrowse[ _oLbxAux:nAT][4],;
									  _aBrowse[ _oLbxAux:nAT][5],;
									  _aBrowse[ _oLbxAux:nAT][6]}  }
	_oLbxAux:AHeaders    := _aCab 
	_oLbxAux:bHeaderClick:= _bHeadClk

	@ 109, 002 Say oSayNDF PROMPT "Nova Data Faturamento: " SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 107, 064 MSGET oGet1 VAR _dDtFatNew SIZE 055, 010 OF oDlg COLORS 0, 16777215 PIXEL
	
	DEFINE SBUTTON oSButton1 FROM 129, 142 Type 01 OF oDlg ENABLE ACTION ( nOpc:=1,oDlg:End() )
	DEFINE SBUTTON oSButton2 FROM 129, 175 Type 02 OF oDlg ENABLE ACTION ( nOpc:=0,oDlg:End() )
			
   ACTIVATE MSDIALOG oDlg CENTERED
			
		
	If nOpc == 1
		If _dDtFatNew > _dLimFt .Or. _dDtFatNew < _dLimAnt
			U_ITMsg("A Data de Faturamento informada não é vaílda. A data digitada foi: " + DToC(_dDtFatNew) + ".",;
                  "Data de Faturamento Informada Invalida!",;
                  "Favor informar uma data maior ou igual a: " + DToC(_dLimAnt) + " ou menor ou igual a " + DToC(_dLimFt) + ".",3) 
			Loop
		Else

            _lMarcouProd:=.F. 
            For _nI2 := 1 To Len( _aBrowse )
                If _aBrowse[_nI2][1]
				   ACOLS[ _aBrowse[_nI2][Len(_aBrowse[_nI2])] ][ nColDtFat ]:=_dDtFatNew
				   _lMarcouProd:=.T. 
				EndIf
            Next _nI2

		    If !_lMarcouProd
               U_ITMsg("Nenhum Produto Selecionado","Atenção","Selecione 1 ou mais produtos",3)
		       Loop
		    Else
            	U_ITMsg("Data de Faturamento alterada de " + DToC(_dDtFatOld) + " para " + DToC(_dDtFatNew) +" com sucesso.","Atenção",,2)
		    EndIf
		EndIf
	EndIf
   Exit
EndDo		
	
FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: ITOrdLbx
Autor-------------: Alex Wallauer
Data da Criacao---: 01/06/2023
Descrição---------: Rotina que Processa a ordenação dos dados do ListBox Genérico conforme parâmetros informados
Parametros--------: oLbxAux - Objeto de Dados do ListBox
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ITOrdLbx( oLbxAux , nCol  )

Local nI		:= 0

If nCol == 1
	For nI := 1 To Len( oLbxAux:aArray )
		oLbxAux:aArray[nI][01] := !oLbxAux:aArray[nI][01]
	Next nI
Else
	If	nCol > 0
		If nCol <> nITPosAnt
			aSort( oLbxAux:aArray ,,, { |x,y| x[nCol] < y[nCol] } )
			nITPosAnt := nCol
		Else
			aSort( oLbxAux:aArray ,,, { |x,y| x[nCol] > y[nCol] } )
			nITPosAnt := 0
		EndIf
	EndIf
EndIf

oLbxAux:Refresh()

Return .T.

/*
===============================================================================================================================
Programa----------: ITDBLCLK
Autor-------------: Alex Wallauer
Data da Criacao---: 01/06/2023
Descrição---------: Processa função do duplo click
Parametros--------: oLbxDados - Objeto de Dados do ListBox
Retorno-----------: lRet	- Caso o usuário saia da tela clicando em "Confirmar" retorna .T.
===============================================================================================================================
*/
Static Function ITDBLCLK( oLbxDados )
	
oLbxDados:aArray[ oLbxDados:nAt , 01 ] := !oLbxDados:aArray[ oLbxDados:nAt , 01 ]
oLbxDados:Refresh()

Return

/*
===============================================================================================================================
Programa----------: MT120DtE  
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/06/2023
Descrição---------: Rotina para alteração de data de Entrega dos itens do pedido de compras.
                    Replica da função de alteração de Data de Faturamento (U_MT120DtFat()), 
					alterada para alterar data de entrega.
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function MT120DtE

Local aArea			:= FWGetArea()
Local _dDtEntNew	:= Ctod("  /  /  ")
Local _dDtEntOld    := Ctod("  /  /  ")
Local _nI2			:= 0
Local nOpc			:= 0
Local nColItem   := aScan(aHeader,{|x|AllTrim(x[2])=="C7_ITEM"})
Local nColProd   := aScan(aHeader,{|x|AllTrim(x[2])=="C7_PRODUTO"})
Local nColDescr  := aScan(aHeader,{|x|AllTrim(x[2])=="C7_DESCRI"})
Local _nPosDtEnt := aScan(aHeader,{|x|AllTrim(x[2])=="C7_DATPRF"})
Local _bHeadClk := {|oObj,nCol| ITOrdLbx( oObj , nCol) }
Local _bDblClk  := {|         | ITDblClk( @_oLbxAux   ) }
Local _nDtLimFt	:= SuperGetMV("IT_DTLIMFT",.F.,180)	// Limite de dias para data de Faturamento
Local _dLimFt	:= Date() + _nDtLimFt			// Data limite maximo para data de Faturamento
Local _dLimAnt	:= Date() - _nDtLimFt			// Data limite minimo para data de Faturamento
Local oOk		:= LoadBitmap( GetResources() , "LBOK" )
Local oNo		:= LoadBitmap( GetResources() , "LBNO" )
Local oGet1
Local oSayNDF
Local oSButton1
Local oSButton2
Local oDlg
Local _aBrowse :={}
Local _aCab := {}
Local _aItensB := {}

Private nITPosAnt := 0

Begin Sequence 
   aAdd(_aCab,"")
   aAdd(_aCab,aHeader[nColItem ,1])
   aAdd(_aCab,aHeader[_nPosDtEnt,1]) 
   aAdd(_aCab,aHeader[nColProd ,1])
   aAdd(_aCab,aHeader[nColDescr,1])
   aAdd(_aCab,"Linha")

   For _nI2 := 1 To Len( acols )
       If aTail(aCols[_nI2]) // Se Linha Deletada
          Loop
       EndIf
       
	   _aItensB:={}
       aAdd(_aItensB,.T.)                     //01
       aAdd(_aItensB,ACOLS[_nI2][nColItem ])  //02
       aAdd(_aItensB,ACOLS[_nI2][_nPosDtEnt]) //03  
       aAdd(_aItensB,ACOLS[_nI2][nColProd ])  //04
       aAdd(_aItensB,ACOLS[_nI2][nColDescr])  //05
       aAdd(_aItensB,_nI2)                    //06
       aAdd(_aBrowse,_aItensB)                    
       
	   If Empty(_dDtEntOld) .And. !Empty(ACols[_nI2][_nPosDtEnt])
	      _dDtEntOld:=ACOLS[_nI2][_nPosDtEnt]
	   EndIf 
   Next _nI2

   _dDtEntNew := _dDtEntOld
   nITPosAnt:= 0

   While .T.

      DEFINE MSDIALOG oDlg TITLE "Altera da Data de Entrega dos Itens do Pedido de Compras" FROM 000, 000  TO 300, 700 COLORS 0, 16777215 PIXEL
			
	     @ 001,002 LISTBOX _oLbxAux FIELDS TITLE "" SIZE 348,101, PIXEL ; // 001, 002, 101, 348,
				   ON		DblClick( Eval(_bDblClk,_oLbxAux) )	

	     _oLbxAux:SetArray( _aBrowse )
	     _oLbxAux:bLine       := {|| { If( _aBrowse[ _oLbxAux:nAT][1] , oOk , oNo ) ,;
	                                       _aBrowse[ _oLbxAux:nAT][2],;
									       _aBrowse[ _oLbxAux:nAT][3],;
									       _aBrowse[ _oLbxAux:nAT][4],;
									       _aBrowse[ _oLbxAux:nAT][5],;
									       _aBrowse[ _oLbxAux:nAT][6]}  }
	     _oLbxAux:AHeaders     := _aCab 
	     _oLbxAux:bHeaderClick := _bHeadClk

	     @ 109, 002 Say oSayNDF PROMPT "Nova Data de Entrega: " SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
	     @ 107, 064 MSGET oGet1 VAR _dDtEntNew SIZE 055, 010 OF oDlg COLORS 0, 16777215 PIXEL
	
	     DEFINE SBUTTON oSButton1 FROM 129, 142 Type 01 OF oDlg ENABLE ACTION ( nOpc:=1,oDlg:End() )
	     DEFINE SBUTTON oSButton2 FROM 129, 175 Type 02 OF oDlg ENABLE ACTION ( nOpc:=0,oDlg:End() )
			
      ACTIVATE MSDIALOG oDlg CENTERED
			
	  If nOpc == 1
		
		 If _dDtEntNew > _dLimFt .Or. _dDtEntNew < _dLimAnt
		    U_ITMsg("A Data de entrega do pedido de compras informada não é vaílda. A data digitada foi: " + DToC(_dDtEntNew) + ".",;
                   "Data de Entrega Informada Invalida!",;
                   "Favor informar uma data maior ou igual a: " + DToC(_dLimAnt) + " ou menor ou igual a " + DToC(_dLimFt) + ".",3) 
		    Loop
		 Else

            _lMarcouProd:=.F. 
            For _nI2 := 1 To Len( _aBrowse )
                If _aBrowse[_nI2][1]
				   ACOLS[ _aBrowse[_nI2][Len(_aBrowse[_nI2])] ][ _nPosDtEnt]:=_dDtEntNew
				   _lMarcouProd:=.T. 
			    EndIf 
            Next  

		    If !_lMarcouProd
               U_ITMsg("Nenhum Produto Selecionado","Atenção","Selecione 1 ou mais produtos",3)
		       Loop
		    Else
               U_ITMsg("Data de Entrega alterada de " + DToC(_dDtEntOld) + " para " + DToC(_dDtEntNew) +" com sucesso.","Atenção",,2)
		    EndIf 
		 EndIf
	  EndIf

      Exit 
   EndDo		

End Sequence 

FWRestArea(aArea)

Return .T.
