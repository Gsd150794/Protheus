/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
Lucas Borges  |17/09/2025| Chamado 52146. Corrigido erro na chamada do SuperGetMV
===============================================================================================================================
*/

#Include "ap5mail.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS114
Autor-------------: Alex Wallauer 
Data da Criacao---: 12/03/2013
Descrição---------: Central de seguros de frete  - Chamado 29372
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS114() 

Private _oTRBF := nil
Private _aTRBF := {}
Private nQtdTit:= 0
Private nValTit:= 0
Private dDtVenc:= Date()
Private _aRecEsto:={}

If DAY(Date()) >  23
   dDtVenc:=CTOD("23/"+StrZero( Month(Date())+1 , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
Else
   dDtVenc:=CTOD("23/"+StrZero( Month(Date())   , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
EndIf
AOMS114INI()

If Select("TRBF") > 0
	If ValType(_oTRBF) == "O"
	   TRBF->(DBCloseArea())
	    _oTRBF:Delete()
	Else
	   TRBF->(DBCloseArea())
	EndIf
EndIf

If Select("TRBSF2") > 0
	TRBSF2->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS114INI
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Funcao que controla o processamento 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114INI()

Private _cPerg		  := 'AOMS114'
Private _cMV_ZP1    := "ITAOMS114TR"
Private _nPercSeguro:= SuperGetMV("IT_PERCSEG",.F.,0.13)//Padrão é 0.13% criar o parametro tipo numerico
Private _dDtCorte   := SuperGetMV("IT_NDFDTCO",.F.,CTOD("01/07/2019") )//
Private _cMarca     := GetMark()
Private _lTemPercDiferente:=.F.
Private _bPergunte := {|| Pergunte( _cPerg , .T. ) }

If ValType(_nPercSeguro) <> "N"
   _nPercSeguro:=0.13/100
Else
   _nPercSeguro:=(_nPercSeguro/100)
EndIf

While .T.
   
   ZP1->(DBSetOrder(2))
   ZP1->(MsSeek( xFilial('ZP1') + cFilant + _cMV_ZP1 ))//TRAVA POR FILIAL
   ZP1->(MsRUnLock())
   ZP1->(MSUnLockALL())
   nOpca:=0
   If EVAL(_bPergunte)
      If !AOM114Trava()
         Loop
      EndIf
      _lTemReg:=.F.
	  // Cria o arquivo Temporario para insercao dos dados selecionados.	
	  FWMsgRun( , {|oProc| _lTemReg:=AOMS114ArQ(oProc) }, "Aguarde!" , 'Lendo Dados das Notas...' )
	  If _lTemReg 
	     nOpca:=AOMS114TRS()
	  Else
         U_ITMsg("Não há registros, altere o filtro!","ATENCAO",,3)
	     Loop
	  EndIf   
	  
	EndIf
	If nOpca <> 3   
	   Exit
	EndIf   
EndDo

ZP1->(DBSetOrder(2))
ZP1->(MSSEEK( xFilial('ZP1') + cFilant + _cMV_ZP1 ))//TRAVA POR FILIAL
ZP1->(MSRUNLOCK())
ZP1->(MSUnLockALL())
ZP1->(DBSetOrder(1))

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS114TRS
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que monta a tela para processar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114TRS()

Local oPanel		:= Nil
Local oDlg1			:= Nil
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}
Local _bVal:={|| If(dDtVenc >= dDataBase,.T.,(U_ITMsg("Data INVALIDA",'Atenção!',"Tente novamente com a data maior ou igual que hoje",3),.F.) ) }
Private nOpca	 := 2
Private cFiltro	 := "" 
Private oMark	 := Nil
Private oQtda	 := Nil
Private oValor   := Nil
// Botoes da tela.
aAdd( aBotoes , { "" , {|| AOMS114LEG() }   , "" , "Legenda"          } )
aAdd( aBotoes , { "" , {|| AOMS114ALL() }   , "" , "Marca/Desm.Todos"} )
aAdd( aBotoes , { "" , {|| AOMS114C(9)	}	  , "" , "Selecionar Notas"    } )
aAdd( aBotoes , { "" , {|| AOMS114C(4)	}	  , "" , "Visualiza NFs"    } )
aAdd( aBotoes , { "" , {|| AOMS114C(2) 	} , "" , "Pesquisar"		  } )
aAdd( aBotoes , { "" , {|| AOMS114C(5) 	} , "" , "Exporta Excel"    } )
// Faz o calculo automatico de dimensoes de objetos
aSize := MSADVSIZE() 

While .T.
 
   nOpca:= 2
   DEFINE MSDIALOG oDlg1 TITLE "CENTRAL DE SEGUROS DE FRETE "+If(MV_PAR06=1,"[ TITULOS GERADOS ]","[ TITULOS NAO GERADOS ]") From 0,0 To aSize[6],aSize[5] PIXEL

	oPanel:= TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )
	oFont := TFont():New('Times New Roman',,-16,.T.)

	_nCol:=005
	_nSize:=60
	_nPula:= 65
	If MV_PAR06 = 1//JÁ EMITIDOS                                                                                    //Loop   ,SAI  
	   @003,_nCol BUTTON "ESTORNA TITULO"   SIZE _nSize, 015 PIXEL OF oPanel ACTION (If(AOMS114C(8),(If(AOMS114C(1),nOpca:=1,nOpca:=3),oDlg1:End()),))//SEM PERGUNTE()
	Else                                                                                                   //Loop   ,SAI  
	   @003,_nCol BUTTON "GERA TITULO"      SIZE _nSize, 015 PIXEL OF oPanel ACTION (If(AOMS114C(6),(If(AOMS114C(1),nOpca:=1,nOpca:=3),oDlg1:End()),))//SEM PERGUNTE()
	EndIf   
	_nCol+=_nPula

   If MV_PAR06 == 2 //Não Emitidos
      @003,_nCol BUTTON "SELECIONAR NOTAS" SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS114C(9)) 
      _nCol+=_nPula
   EndIf 

	@003,_nCol BUTTON "VISUALIZA NFS" SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS114C(4))
	_nCol+=_nPula

	@003,_nCol BUTTON "PESQUISAR"     SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS114C(2))
	_nCol+=_nPula
                                                                                              //Loop   ,SAI  
    @003,_nCol BUTTON "ATUALIZAR"     SIZE _nSize, 015 PIXEL OF oPanel ACTION ( If(AOMS114C(3),nOpca:=1,nOpca:=3),oDlg1:End() )//COM PERGUNTE()
	_nCol+=_nPula

	If MV_PAR06 = 1//JÁ EMITIDOS 
	   @003,_nCol BUTTON "RE-ENVIA E-MAIL" SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS114C(7))
	   _nCol+=_nPula
	EndIf   

	@003,_nCol BUTTON "MARCA/DESM.TODOS" SIZE _nSize, 015 PIXEL OF oPanel ACTION AOMS114ALL()
	_nCol+=_nPula

	TSay():New(05,_nCol,{||'Vencimento:'},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,18)
	_nCol+=_nPula
	_nCol-=25

    @ 05,_nCol MSGET dDtVenc Size 050,10 COLORS CLR_RED,CLR_WHITE Picture "@D" PIXEL OF oPanel FONT oFont  VALID Eval(_bVal)
    _nCol+=(_nPula-9)

	oQtda := TSay():New(05,_nCol,{||'Qtde transp: '+AllTrim(TRANSFORM(nQtdTit,"@E 99,999,999,999"))},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)//450
	_nCol+=(_nPula)

	oValor:= TSay():New(05,_nCol,{||'Valor seguro: '+AllTrim(TRANSFORM(nValTit,"@E 9999,999,999.99"))},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)//550
	
	If FlatMode()
		aCoors	:= GetScreenRes()
		nHeight	:= aCoors[2]
		nWidth	:= aCoors[1]
	Else
		nHeight	:= 143
		nWidth	:= 315
	EndIf

  //TCBrowse():New( [ nRow ], [ nCol ], [ nWidth ], [ nHeight ], [ bLine ], [ aHeaders ], [ aColSizes ], [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ]  , [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
	oMark := TCBrowse():New(35,  01   , 35+nHeight, 01+nwidth  ,          ,             ,              , oDlg1   ,           ,            ,            ,            ,                 ,            ,          ,            ,             ,             ,         ,    .F.      ,           ,   .T.     ,          ,    .F.      ,           ,             ,              )

	oMark:SetArray(_aTRBF)
	oMark:bHeaderClick := {|| AOMS114ALL()}
	oMark:bLDblClick   := {|| AOMS114INV()}
	
	oMark:AddColumn(TCColumn():New(" "       			      ,{|| LoadBitmap(GetResources(), If(Len(_aTRBF)>0,If(_aTRBF[oMark:nat,01]==_cMarca,"LBOK","LBNO"),"LBNO") ) },,,,,,.T.,.F.,,,,.F., ) )
  	oMark:AddColumn(TCColumn():New(" "       			      ,{|| LoadBitmap(GetResources(), If(Len(_aTRBF)>0,U_AOMS1149(_aTRBF[oMark:nat,14]),' '))  },    ,,,,,.T.,.F.,,,,.F., ) )
	oMark:AddColumn(TCColumn():New("Codigo"               ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,03], ' ') },"@!"       			  ,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark:AddColumn(TCColumn():New("Lojas"                ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,04], ' ') },"@!"       			  ,,,"LEFT" ,050,.F.,.F.,,,,,))

	oMark:AddColumn(TCColumn():New("Transportador"		   ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,05], ' ') },"@!"       			  ,,,"LEFT" ,250,.F.,.F.,,,,,))
	oMark:AddColumn(TCColumn():New("Valor Mercadoria"	   ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,08], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
   oMark:AddColumn(TCColumn():New("Frete" 				   ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,11], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
	oMark:AddColumn(TCColumn():New("Valor Bruto" 		   ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,09], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
   If !_lTemPercDiferente
      oMark:AddColumn(TCColumn():New("% Seguro" 			   ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,12], ' ') },"@E 99,999,999,999.999",,,"RIGHT",050,.F.,.F.,,,,,))
   EndIf
	oMark:AddColumn(TCColumn():New("Seguro" 			      ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,13], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
	oMark:AddColumn(TCColumn():New("Qtde NFs"    		   ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,10], ' ') },"@E 999,999,999,999"   ,,,"CENTER",050,.F.,.F.,,,,,))
	oMark:AddColumn(TCColumn():New("Chave do Titulo"      ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,14], ' ') },"@!"       			  ,,,"LEFT" ,050,.F.,.F.,,,,,))

	oDlg1:lMaximized:=.T.

   ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,{|| nOpca:= 2,oDlg1:End() },;
                                                       {|| nOpca:= 2,oDlg1:End() },,aBotoes),;
                                     oPanel:Align:=CONTROL_ALIGN_TOP ,;
                                     oMark:Align:=CONTROL_ALIGN_ALLCLIENT ,;
                                     oMark:Refresh())
    If nOpca = 1
       Loop
    ElseIf nOpca = 2  .And. !U_ITMsg("Confirmar Sair ?",'Atenção!',,3,2,2)
       Loop
    EndIf

    Exit

EndDo 

Return nOpca

/*
===============================================================================================================================
Programa----------: AOMS114INV
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function AOMS114INV()

Local _nlinpos := oMark:nat

TRBF->(DBGoTo(_aTRBF[_nlinpos,15]))

//Duplo clique na marcação
If AllTrim(_cMarca)==AllTrim(_aTRBF[_nlinpos,01])
   nQtdTit--
   nValTit-= TRBF->SEGURO
   _aTRBF[_nlinpos,01] := "  "
Else
   nQtdTit++
   nValTit+= TRBF->SEGURO
   _aTRBF[_nlinpos,01] := _cMarca
EndIf

nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )
nValTit := IIf( nValTit < 0 , 0 , nValTit )

TRBF->OK := _aTRBF[_nlinpos,01]

oQtda:Refresh()
oValor:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS114ALL
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114ALL()

Local nReg     := _aTRBF[oMark:nAt,15]
Local _nnp     := 1
Local _cMarcALL:= If(_aTRBF[nReg,1]==_cMarca,Space(2),_cMarca)//OU MARCA TODOS OU DESMARCA TODOS

For _nnp := 1 To Len(_aTRBF)

	TRBF->(DBGoTo(_aTRBF[_nnp,15]))

	If !Empty(_aTRBF[_nnp,1]) .And.  Empty(_cMarcALL)
	
		TRBF->OK       := Space(2)                     
		
		_aTRBF[_nnp,01]:= Space(2)
		nQtdTit--
		nValTit-= TRBF->SEGURO

	ElseIf Empty(_aTRBF[_nnp,1]) .And. !Empty(_cMarcALL)
	
		TRBF->OK       := _cMarca
		_aTRBF[_nnp][1]:= _cMarca
		nQtdTit++
		nValTit+= TRBF->SEGURO
		
	EndIf
	
	nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )
	nValTit := IIf( nValTit < 0 , 0 , nValTit )
	
Next

TRBF->( DBGoTo(nReg) )
oQtda:Refresh()
oValor:Refresh()
oMark:Refresh()
ProcessMessages()

Return

/*
===============================================================================================================================
Programa----------: AOMS114Arq
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: oProc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114Arq(oProc)

Local aEstru  := {}
Local cFiltro := "" 
Local _cQuery1:= ""
Local _npv    := 0
Local _lTemReg:=.F.
Local _nPerTransp, _nPSeguro

//GARANTE QUE O PERGUNTE ESTA CORRETO
Pergunte( _cPerg , .F. )

// Armazena no array aEstru a estrutura dos campos da tabela.
aEstru := {	{ "OK"			 , "C" , 002 , 0 } ,;
            { "COD"	  		 , "C" , Len(SA2->A2_COD)  , 0 } ,;
            { "A2_LOJA"		 , "C" , Len(SA2->A2_LOJA) , 0 } ,;
            { "F2_I_NDFSE"  , "C" , Len(SF2->F2_I_NDFSE),0} ,;                        
	   		{ "TRANSP"	    , "C" , 040 , 0 } ,;
            { "LOJATRANSP"	 , "C" , 100, 0 } ,;
	   		{ "CNPJ"	  	    , "C" , 020 , 0 } ,;
	   		{ "UF"	    	 , "C" , 002 , 0 } ,;
	   		{ "TOTAL"	  	 , "N" , 018 , 2 } ,;
	   		{ "BRUTO"	    , "N" , 018 , 2 } ,;
	   		{ "QTDENF"      , "N" , 018 , 0 } ,;
		   	{ "FRETE"       , "N" , 018 , 2 } ,;
            { "ALIQS"       , "N" , 018 , 6 } ,;
		   	{ "SEGURO"      , "N" , 018 , 4 }  }

// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
If Select("TRBF") > 0
	If ValType(_oTRBF) == "O"
	   TRBF->(DBCloseArea())
	    _oTRBF:Delete()
	Else
	   TRBF->(DBCloseArea())
	EndIf
EndIf

oProc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()
_oTRBF := FWTemporaryTable():New( "TRBF", aEstru )

oProc:cCaption := ("Criando indices do arquivo temporário...")
ProcessMessages()
_oTRBF:AddIndex( "TR", {"TRANSP"} )//NOME
_oTRBF:AddIndex( "CO", {"COD","F2_I_NDFSE"} )

_oTRBF:Create()

oProc:cCaption := ("Lendo dados das notas...")
ProcessMessages()

cFiltro:=AOMS114Filtro(.F.,.F.)

_cQuery1+= " SELECT 	DISTINCT SF2.F2_FILIAL,  SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, "
_cQuery1+= "			SF2.F2_I_CTRA AS TRANSP,  "
_cQuery1+= "         SF2.F2_I_NDFSE,           "
_cQuery1+= "         SF2.F2_VALMERC, "
_cQuery1+= "         SF2.F2_I_FRET , "
_cQuery1+= "         SF2.F2_VALBRUT, " 
//_cQuery1+= "         1 AS QTDENF, " 
_cQuery1+= "         SF2.F2_I_CTRA   AS TRANSPORT,   "            // Transportadora
_cQuery1+= "         SF2.F2_I_LTRA   AS LOJATRANSP, "               // Loja Transportadora
_cQuery1+= "         SA2.A2_NOME, SA2.A2_I_AVERB, SA2.A2_COD ,SA2.A2_LOJA, SA2.A2_EST,SA2.A2_NREDUZ,"
_cQuery1+= "         SF2.R_E_C_N_O_ SF2_REC "
_cQuery1+= "		FROM " + RetSqlName("SF2")+" SF2         "
_cQuery1+= "		JOIN " + RetSqlName("SA2")+" SA2 ON SA2.A2_COD	= SF2.F2_I_CTRA   AND SA2.A2_LOJA    = SF2.F2_I_LTRA "

If !Empty(MV_PAR04)  
   _cQuery1+= "		JOIN " + RetSqlName("SD2")+" SD2 "
   _cQuery1+= "		    ON  SD2.D2_FILIAL  = SF2.F2_FILIAL  "
   _cQuery1+= "		    AND SD2.D2_DOC     = SF2.F2_DOC     " 
   _cQuery1+= "		    AND SD2.D2_SERIE   = SF2.F2_SERIE   "
   _cQuery1+= "		    AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
   _cQuery1+= "		    AND SD2.D2_LOJA    = SF2.F2_LOJA    "
EndIf 

_cQuery1+= "  WHERE     SF2.D_E_L_E_T_ = ' ' "
_cQuery1+= "		AND SA2.D_E_L_E_T_ = ' ' "
_cQuery1+= "		AND SF2.F2_CARGA  <> ' ' "

If MV_PAR06 = 1//JÁ EMITIDOS  
   _cQuery1+= "		AND SF2.F2_I_GERTS <> 'N' " 
EndIf

_cQuery1+= cFiltro
_cQuery1+= " ORDER BY SF2.F2_I_NDFSE, SF2.F2_I_CTRA , SF2.F2_I_LTRA"

_cAlias:=GetNextAlias()
MPSysOpenQuery( _cQuery1 , _cAlias ) 

TCSetField( _cAlias, "F2_EMISSAO", "D", 8, 0)

oProc:cCaption := ("Contando os dados lidos...")
ProcessMessages()
DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop())
_cTot := 0
COUNT To _cTot
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
(_cAlias)->(DBGoTop())

_aTRBF := {}
nQtdTit:= 0
nValTit:= 0
SA2->(DBSetOrder(1)) 

If Select("TRBSF2") > 0
   TRBSF2->(DBCloseArea())
EndIf

TRBF->(DBSetOrder(2)) //"COD","F2_I_NDFSE"

While (_cAlias)->(!Eof())

	//Atualiza régua
	_npv++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()

   _nPerTransp := Posicione('ZGX',1,xFilial("ZGX")+(_cAlias)->F2_FILIAL+(_cAlias)->TRANSP+(_cAlias)->A2_LOJA,'ZGX_PERSEG')
   If ! Empty(_nPerTransp)
      If !_lTemPercDiferente//Se mudou para .T. tem que ficar .T.
         _lTemPercDiferente:=(_nPerTransp<>_nPercSeguro)
      EndIf
      _nPSeguro := (_nPerTransp/100)
   Else
      _nPSeguro := _nPercSeguro
   EndIf 
 
   If !TRBF->(DBSeek( (_cAlias)->TRANSP+(_cAlias)->F2_I_NDFSE ))//ORDEM 2
       TRBF->(DBAPPEND())
       TRBF->COD		   := (_cAlias)->TRANSP
       TRBF->A2_LOJA    := (_cAlias)->LOJATRANSP//PEGO A PRIMEIRA LOJA QUE ACHAR
       TRBF->LOJATRANSP := (_cAlias)->LOJATRANSP//PEGO A PRIMEIRA LOJA QUE ACHAR
	    TRBF->TRANSP		:= (_cAlias)->A2_NOME
       TRBF->F2_I_NDFSE := (_cAlias)->F2_I_NDFSE
	    TRBF->ALIQS 		:= _nPSeguro * 100              

	    If Empty(TRBF->F2_I_NDFSE) .Or. MV_PAR06 = 1//SIM: JÁ EMITIDOS
	       _cOK:=_cMarca
	    Else
          _cOK:="  "
	    EndIf   
  	    TRBF->OK:=_cOK
    
       If !Empty(TRBF->OK)//SÓ OS MARCADOS
	       nQtdTit++
	    EndIf   
        _lTemReg:=.T.

   ElseIf !(_cAlias)->LOJATRANSP $ TRBF->LOJATRANSP
       TRBF->LOJATRANSP := AllTrim(TRBF->LOJATRANSP)+"-"+(_cAlias)->LOJATRANSP//SOMA AS LOJAS DIFERENTES
   EndIf

   TRBF->TOTAL       += (_cAlias)->F2_VALMERC
	TRBF->FRETE   		+= (_cAlias)->F2_I_FRET
	TRBF->BRUTO   		+= (_cAlias)->F2_VALBRUT
	TRBF->SEGURO		+= _nPSeguro * (_cAlias)->F2_VALBRUT 
	TRBF->QTDENF   	+= 1

   If !Empty(TRBF->OK)//SÓ OS MARCADOS
	   nValTit+= _nPSeguro * (_cAlias)->F2_VALBRUT
	EndIf   
	
   AOMS114B(oProc,_cAlias)

    (_cAlias)->( DBSkip() )

EndDo

(_cAlias)->( DBCloseArea())

oProc:cCaption := ("Re-Ordenando Dados...")
ProcessMessages()
_aTRBF:={}
TRBF->(DBSetOrder(1))//NOME da transportadora
TRBF->(DBGoTop())
While TRBF->(!Eof())
    _aItens:={}
	aAdd(_aItens,TRBF->OK)                 //01                                    
	aAdd(_aItens,"")                       //02 //CAMPO FILLER
	aAdd(_aItens,TRBF->COD)                //03                   
	aAdd(_aItens,TRBF->LOJATRANSP)		   //04 //LOJAS
	aAdd(_aItens,TRBF->TRANSP)             //05 
	aAdd(_aItens,"")               		   //06 //CAMPO FILLER                
 	aAdd(_aItens,"") 		                  //07 //CAMPO FILLER  
 	aAdd(_aItens,TRBF->TOTAL)		         //08
 	aAdd(_aItens,TRBF->BRUTO)              //09
 	aAdd(_aItens,TRBF->QTDENF)		         //10
 	aAdd(_aItens,TRBF->FRETE)              //11    
 	aAdd(_aItens,TRBF->ALIQS)              //12  
 	aAdd(_aItens,TRBF->SEGURO)             //13     
 	aAdd(_aItens,TRBF->F2_I_NDFSE)         //14 //CAMPO FILLER
 	aAdd(_aItens,TRBF->(RECNO()) )         //15    
	aAdd(_aTRBF,_aItens)
   TRBF->( DBSkip() )
EndDo
TRBF->(DBGoTop())

//Se browse já está montando garante que array está atualizado
If Type("oMark") == "O" .And. Len(_aTRBF) > 0

   oQtda:Refresh()
   oValor:Refresh()
	oMark:setarray(_aTRBF)
	oMark:refresh()
	TRBF->(DBGoTo(_aTRBF[oMark:NAT,15]))

EndIf

Return _lTemReg

/*
===============================================================================================================================
Programa----------: AOMS114C()
Autor-------------: Alex Wallauer 
Data da Criacao---: 02/10/2018
Descrição---------: Chamada de itens do menu
Parametros--------: _nOpcao - Opção do menu
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114C(_nOpcao)

If Len(_aTRBF) > 0
   TRBF->(DBGoTo(_aTRBF[oMark:NAT,15]))
ElseIf _nOpcao <> 3
   U_ITMsg("Não há registros, altere o filtro!")
   Return .F.
EndIf

Do Case

Case _nOpcao == 1 //Atualizar AÇÕES RELACIONADAS SEM PERGUNTE()

	 Return .F. //01/002/2023 agora sai sempre (não recarrega e volta para tela)
     _lTemReg:=.F.
	 FWMsgRun(,{ |oProc| _lTemReg:=AOMS114Arq(oProc) }, "Aguarde...","Carregando dados...")
	 If !_lTemReg
	    U_ITMsg("Não há registros, altere o filtro!","ATENCAO",,3)
	 EndIf   
	 Return _lTemReg
	
Case _nOpcao == 2 //Pesquisa

	 AOMS114PSQ()

Case _nOpcao == 3 //Atualizar BOTÃO COM PERGUNTE()

     _lRet:=.F.
	 FWMsgRun(,{ |oProc| _lRet:=AOMS114Atu(oProc) }, "Aguarde...","Carregando dados...")
	 Return _lRet

Case _nOpcao == 4	//Visualiza NFs
     _aRecEsto:={}//ZERA POR SEGURANÇA 
                                 //oProc,_cChave,_nRecTRBF,_lGrava,_lSoma
	 FWMsgRun(,{ |oProc| AOMS114NF(oProc,""     ,         ,.F.    ,(MV_PAR06=1)) }, "Aguarde...","Carregando dados...")
	
Case _nOpcao == 5	//Exporta Excel

	 FWMsgRun(,{ |oProc| AOMS114XC(oProc) }, "Aguarde...","Carregando dados...")

Case _nOpcao == 6	//Gera NDF
     
     If U_ITMsg("Confirmar Geracao de Titulos ?",'Atenção!',,3,2,2)
        _lRet:=.F.
  	    FWMsgRun(,{ |oProc| _lRet:=AOMS114GE(oProc,.F.,.T.) }, "Aguarde...","Gerando Titulo do Seguro...")//ENVIA E-MAIL SEM TELA
	    Return _lRet
     Else
	    Return .F.
     EndIf

Case _nOpcao == 7	//ENVIA - EMAIL

	FWMsgRun(,{ |oProc| _lRet:=AOMS114GE(oProc,.T.,.T.) }, "Aguarde...","Lendo Titulo do Seguro...")//ENVIA E-MAIL COM TELA

Case _nOpcao == 8	//Estorna NDF
     
     If U_ITMsg("Confirmar Estorno de Titulos ?",'Atenção!',,3,2,2)
        _lRet:=.F.
  	    FWMsgRun(,{ |oProc| _lRet:=AOMS114GE(oProc,.F.,.F.) }, "Aguarde...","Estorno Titulo do Seguro...")//ENVIA E-MAIL SEM TELA
	    Return _lRet
     Else
	    Return .F.
     EndIf

Case _nOpcao == 9	// Permite selecionar Notas para geração dos titulos.  
                                 
	 FWMsgRun(,{ |oProc| U_AOMS114R() }, "Aguarde...","Carregando dados...")


EndCase

If Len(_aTRBF) > 0
   TRBF->(DBGoTo(_aTRBF[oMark:NAT,15]))
EndIf


Return .T.

/*
===============================================================================================================================
Programa--------: AOMS1149
Autor-----------: Alex Wallauer 
Data da Criacao-: 18/02/2014
Descrição-------: Retorna cor e legenda
Parametros------: _cMarca: Marcacao
Retorno---------: string com cor da legenda da linha posicionada no TRBF
===============================================================================================================================
*/
User Function AOMS1149(_cMarca)

If Empty(_cMarca)
   Return "BR_VERDE"
Else
   Return "BR_AZUL"
EndIf

Return "BR_VERMELHO"


/*
===============================================================================================================================
Programa----------: AOMS114Atu
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Função que refaz filtro da tela
Parametros--------: oProc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114Atu(oProc)

Local _lTemReg:=.T.//INICIA COM .T. PQ NA PRIMIERA FEZ QUE ENTRA ESTA COM REGISTROS, e o usuario pode cancelar o pergunte
While .T.
   If EVAL(_bPergunte)
      _lTemReg:=.F.
	  // Cria o arquivo Temporario para insercao dos dados selecionados.	
	  FWMsgRun( , {|oProc| _lTemReg:=AOMS114ArQ(oProc) }, "Aguarde!" , 'Lendo Dados das Notas...' )
	  If _lTemReg 
	     Return .T.
	  Else
         U_ITMsg("Não há registros, altere o filtro!","ATENCAO",,3)
	     Loop
	  EndIf	  
	EndIf  
	Exit
EndDo

Return _lTemReg

/*
===============================================================================================================================
Programa----------: AOMS114PSQ
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2018
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: oProc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function AOMS114PSQ( oProc)

Local oGet1		:= Nil  , nI
Local oDlg		:= Nil
Local cGet1		:= Space(40)
Local cComboBx1	:= ""
Local aComboBx1	:= { "Nome do Transportador","Codigo do Transportador" }
Local nOpca		:= 0

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 To 259,697 PIXEL

	@004,003 ComboBox	cComboBx1	Items aComboBx1 Size 213,010 OF oDlg PIXEL
	@020,003 MsGet		oGet1		Var cGet1		Size 212,009 OF oDlg PIXEL COLOR CLR_BLACK Picture "@!"
	
	DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( nOpca := 1 , oDlg:End() ) OF oDlg
	DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( nOpca := 0 , oDlg:End() ) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1

	For nI := 1 To Len(aComboBx1)
	
		If cComboBx1 == aComboBx1[nI]
		
			DBSelectArea("TRBF")
			TRBF->( DBSetOrder(nI) )
			
			If TRBF->(DBSeek( AllTrim(cGet1) ))
			
				_nPos := aScan(_aTRBF,{|x| x[15] == TRBF->(Recno())})
				oMark:GOPOSITION(_nPos)
				oMark:Refresh()

			Else

				U_ITMsg("Transportador não encontrado","Atenção",,1)

			EndIf

			
		EndIf
		
	Next nI
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS114LEG
Autor-----------: Erich Buttner
Data da Criacao-: 09/09/2010
Descrição-------: Exibe a tela de detalhes da legenda
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114LEG()

Local _aLegenda:={}
aAdd(_aLegenda, { "BR_VERDE"   ,"Transp. / NF sem NDF gerado"} )
aAdd(_aLegenda, { "BR_AZUL"    ,"Transp. com NDF gerado"     } )
aAdd(_aLegenda, { "BR_VERMELHO","Nota com NDF gerado"        } )

BrwLegenda("Titulo de Seguros","Legenda" ,_aLegenda)										

Return(.T.)

/*
===============================================================================================================================
Programa----------: AOMS114XC()
Autor-------------: Alex Wallauer 
Data da Criacao---: 11/03/2019
Descrição---------: Exporta browse para o excel
Parametros--------: oProc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114XC(oProc)

Local _aExcel := {}  , _nnh
Local _aCabec := {}
Local _aItens := {}
Local _cTot:=AllTrim(Str(Len(_aTRBF)))
Local _nTam:=Len(_cTot)
Local _npv :=0

aAdd(_aCabec,"Codigo")         //03
aAdd(_aCabec,"Transportador" ) //05
aAdd(_aCabec,"Valor Total")    //08
aAdd(_aCabec,"Frete")          //11
aAdd(_aCabec,"% Seguro")       //12
aAdd(_aCabec,"Seguro")         //13
aAdd(_aCabec,"Chave do Titulo")//14

For _nnh := 1 To Len(_aTRBF)
 	_npv++ 
	 oProc:cCaption := ("Lendo dados: "+StrZero(_npv,_nTam) +" de "+ _cTot)
    ProcessMessages()
    _aItens:={}
    aAdd(_aItens,_aTRBF[_nnh,03])
    aAdd(_aItens,_aTRBF[_nnh,05])
    aAdd(_aItens,_aTRBF[_nnh,08])
	aAdd(_aItens,_aTRBF[_nnh,11])
	aAdd(_aItens,_aTRBF[_nnh,12])
	aAdd(_aItens,_aTRBF[_nnh,13])
	aAdd(_aItens,_aTRBF[_nnh,14])
    aAdd(_aExcel,_aItens)
Next

If Len(_aExcel) > 0
	U_ITLISTBOX("Seguro por transportador" , _aCabec , _aExcel , .T. , 1 )
Else
	U_ITMsg("Nenhum registro selecionado!","Atenção",,1)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS114 NF()
Autor-------------: Alex Wallauer 
Data da Criacao---: 10/07/2019
Descrição---------: Visualiza Nfs do transportador. ATENCAO TEM 3 CHAMADAS DESSA FUNÇÃO COM 4 SITUACOES
Parametros--------: oProc,_cChave,_nRecTRBF,_lGrava,_lSoma,lGera
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114NF(oProc,_cChave,_nRecTRBF,_lGrava,_lSoma,_lGera)

Local _aLinhas := {}
Local _aCab    := {}
Local cFiltro  := ""
Local _npv     := 0
Local _nPerTransp, _nPSeguro
Local _cNfGerTit
Local _nTotNfs
Local _cNFTitSeg 

Default _cChave:= ""
Default _lGrava:= .F.
Default _lSoma := .F.
Default _lGera := .F.
Default _nRecTRBF:=_aTRBF[oMark:NAT,15]
TRBF->(DBGoTo(_nRecTRBF))

oProc:cCaption:="Lendo Notas do Transportador: "+LEFT(TRBF->TRANSP,30)
ProcessMessages()

cFiltro:=AOMS114Filtro(.T.,_lGera)

_cQuery1:= " SELECT DISTINCT " 
_cQuery1+= " SF2.F2_FILIAL , "
_cQuery1+= " SF2.F2_DOC    , "
_cQuery1+= " SF2.F2_SERIE  , "
_cQuery1+= " SF2.F2_EMISSAO, "
_cQuery1+= " SA2.A2_I_AVERB, " 
_cQuery1+= " SA2.A2_LOJA   , " 
_cQuery1+= " SA2.A2_EST    , "
_cQuery1+= " SA2.A2_NREDUZ , " 
_cQuery1+= " SF2.F2_I_NDFSE, "
_cQuery1+= " SF2.F2_I_FRET , "
_cQuery1+= " SF2.F2_VALMERC, "
_cQuery1+= " SF2.F2_VALBRUT TOTAL, " 
_cQuery1+= " SF2.R_E_C_N_O_ SF2_REC, "
_cQuery1+= " SF2.F2_I_CTRA AS TRANSPORT, "  // Transportadora
_cQuery1+= " SF2.F2_I_LTRA AS LOJATRANSP, "  // Loja Transportadora 
_cQuery1+= " SF2.F2_I_GERTS "

_cQuery1+= "		FROM " + RetSqlName("SF2")+" SF2 "
_cQuery1+= "		JOIN " + RetSqlName("SA2")+" SA2 ON SA2.A2_COD = SF2.F2_I_CTRA	AND SA2.A2_LOJA	 = SF2.F2_I_LTRA "

If !Empty(MV_PAR04)  
   _cQuery1+= "		JOIN " + RetSqlName("SD2")+" SD2 "
   _cQuery1+= "		    ON  SD2.D2_FILIAL  = SF2.F2_FILIAL  "
   _cQuery1+= "		    AND SD2.D2_DOC     = SF2.F2_DOC     " 
   _cQuery1+= "		    AND SD2.D2_SERIE   = SF2.F2_SERIE   "
   _cQuery1+= "		    AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
   _cQuery1+= "		    AND SD2.D2_LOJA    = SF2.F2_LOJA    "
EndIf 

_cQuery1+= "		WHERE SF2.D_E_L_E_T_ = ' '	"
_cQuery1+= "		  AND SA2.D_E_L_E_T_ = ' '	"
_cQuery1+= "		  AND SF2.F2_CARGA  <> ' '  "
_cQuery1+= cFiltro
If !_lGrava
   _cQuery1+= "        ORDER BY F2_I_NDFSE,SF2.F2_FILIAL,SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO "
EndIf

If Select("NFS") > 0
	NFS->(DBCloseArea())
EndIf

MPSysOpenQuery( _cQuery1 , "NFS" )  

// 27 Caracteres // F2_I_NDFSE 

DBSelectArea("NFS")
_cTot := 0
oProc:cCaption:="Contando Notas do Transportador: "+LEFT(TRBF->TRANSP,30)
ProcessMessages()
If Len(_aRecEsto) > 0
   _cTot:=Len(_aRecEsto)
Else
   COUNT To _cTot
EndIf   

If Select("TRBSF2") > 0 
   TRBSF2->(DBSetOrder(2))
EndIf 

_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)+1
NFS->(DBGoTop())

_aTotais:={0,0,0,0,0,0,0,0,0,0}

_nTotNfs := 0 

While NFS->(!Eof())

	_npv++

   If _lGrava
  	  oProc:cCaption := ("Gravando Nota: "+NFS->F2_DOC+"/"+NFS->F2_SERIE+" - "+ StrZero(_npv,_nTam) +" de "+ _cTot)
	  ProcessMessages()
      SF2->( DBGoTo(NFS->SF2_REC) )
      If _lGera .And. Empty(SF2->F2_I_NDFSE)//QUANDO GERA
         _cNfGerTit := ""
         TRBSF2->(MsSeek(StrZero(NFS->SF2_REC,10))) 
         If Empty(TRBSF2->WK_OK) 
            _cNfGerTit := "N"
         Else
            _cNfGerTit := "S"
            _nTotNfs += 1
         EndIf
         SF2->(RecLock("SF2",.F.))
         SF2->F2_I_NDFSE:=_cChave 
         SF2->F2_I_GERTS := _cNfGerTit 
         SF2->(MSUnLock())
      ElseIf !_lGera .And. !Empty(SF2->F2_I_NDFSE)//QUANDO ESTORNA
         If SF2->F2_I_GERTS <> "N"            
            _nTotNfs += 1
         EndIf
         SF2->(RecLock("SF2",.F.))
         SF2->F2_I_NDFSE:=""
         SF2->F2_I_GERTS := "N"       
         aAdd(_aRecEsto,NFS->SF2_REC)
         SF2->(MSUnLock())
      EndIf   
      NFS->(DBSkip())
      Loop// SE _lGrava = .T. SÓ VAI ATE AQUI
   EndIf   

    If Len(_aRecEsto) > 0 .And. aScan(_aRecEsto,NFS->SF2_REC) = 0//DA TELA DO RESULTADO DO ESTORNO
       NFS->(DBSkip())
       Loop
    EndIf
	oProc:cCaption := ("Lendo Nota: "+NFS->F2_DOC+"/"+NFS->F2_SERIE+" - "+StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()

   _nPerTransp := Posicione('ZGX',1,xFilial("ZGX")+NFS->F2_FILIAL+NFS->TRANSPORT+NFS->LOJATRANSP,'ZGX_PERSEG')
   If ! Empty(_nPerTransp)
      _nPSeguro := _nPerTransp
   Else
      _nPSeguro := _nPercSeguro
   EndIf
 
   _cNFTitSeg := ""
   If Len(_aRecEsto) > 0 //DA TELA DO RESULTADO DO ESTORNO NÃO MOSTRA MENSAGEM Nenhuma
      _cNFTitSeg := ""
   ElseIf _lSoma .Or. MV_PAR06 = 1//JÁ EMITIDOS
      If NFS->F2_I_GERTS <> "N"
         _cNFTitSeg := "NF UTILIZADA CALCULO SEGURO"
      Else
         _cNFTitSeg := "NF NÃO UTILIZADA CALCULO SEGURO"
      EndIf
   EndIf 
 
   _aItens:={}
   If _lSoma 
      aAdd(_aItens,(NFS->F2_I_GERTS <> "N"))//01
   Else
      aAdd(_aItens,Empty(NFS->F2_I_NDFSE))//01
   EndIf
	aAdd(_aItens,NFS->F2_DOC+"/"+NFS->F2_SERIE)//02 
	aAdd(_aItens,DToC(SToD(NFS->F2_EMISSAO)))//03
	aAdd(_aItens,TRANSFORM(NFS->TOTAL* _nPSeguro,"@E 999,999,999.9999") )// _nPercSeguro,"@E 999,999,999.9999") )//04
  	aAdd(_aItens,TRANSFORM(NFS->TOTAL             ,"@E 999,999,999.99") )//06
	aAdd(_aItens,TRANSFORM(NFS->F2_VALMERC        ,"@E 999,999,999.99") )//05
	aAdd(_aItens,TRANSFORM(NFS->F2_I_FRET         ,"@E 999,999,999.99") )//07
	aAdd(_aItens,NFS->A2_I_AVERB)
	aAdd(_aItens,NFS->A2_EST)
	aAdd(_aItens,NFS->A2_LOJA)
	aAdd(_aItens,NFS->A2_NREDUZ)
	aAdd(_aItens,_cNFTitSeg)
   aAdd(_aItens,NFS->F2_I_NDFSE)
	aAdd(_aLinhas,_aItens)

    //CONTA NA OPCAO EMITIDOS OU SE NÃO EMITIDOS E ESTIVER EM BRANCO F2_I_NDFSE
    If _lSoma .Or. Empty(NFS->F2_I_NDFSE)
       If NFS->F2_I_GERTS <> "N"
          _aTotais[1]+=NFS->TOTAL * _nPSeguro // _nPercSeguro
          _aTotais[2]+=NFS->TOTAL
          _aTotais[3]+=NFS->F2_VALMERC
          _aTotais[4]+=NFS->F2_I_FRET
          _aTotais[7]++
       EndIf 
    ElseIf !Empty(NFS->F2_I_NDFSE)//CONTA QUANDO NÃO EMITIDOS MAS TEM ALGUMAS NOTAS GERADAS
       If NFS->F2_I_GERTS <> "N"
          _aTotais[8]+=NFS->TOTAL * _nPSeguro // _nPercSeguro   
       EndIf 
    EndIf   

	NFS->(DBSkip())

EndDo

_cTot:=AllTrim(Str(_nTotNfs))
 
If !Empty(_cChave)
   Return _cTot
EndIf
If Len(_aLinhas) = 0
   U_ITMsg("Nenhum Nota localizada","Atenção",,1)
   Return .F.
EndIf

_aItens:={}
If (_aTotais[7]) > 0
   aAdd(_aItens,.T.)//01
   aAdd(_aItens,"TOTAIS:")//02
   aAdd(_aItens,AllTrim(Str(_aTotais[7]))+" Notas")//03
   aAdd(_aItens,TRANSFORM(_aTotais[1],"@E 999,999,999,999.99") )//04
   aAdd(_aItens,TRANSFORM(_aTotais[2],"@E 999,999,999,999.99") )//05
   aAdd(_aItens,TRANSFORM(_aTotais[3],"@E 999,999,999,999.99") )//06
   aAdd(_aItens,TRANSFORM(_aTotais[4],"@E 999,999,999,999.99") )//07
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
EndIf

aAdd(_aLinhas,_aItens)

//Monta _aCab
aAdd(_aCab,"")
aAdd(_aCab,"Nota/Serie")   
aAdd(_aCab,"Emissao")      //07
aAdd(_aCab,"Seguro")       //01
aAdd(_aCab,"Valor Bruto")//02
aAdd(_aCab,"Valor Mercadoria") //03
aAdd(_aCab,"Frete") //04
aAdd(_aCab,"Averbacao")    
aAdd(_aCab,"Estado")       
aAdd(_aCab,"Loja")         
aAdd(_aCab,"Nome Transportador")
aAdd(_aCab,"Calculo Titulo Seguro")
aAdd(_aCab,"Chave Gerada")      

If Len(_aLinhas) > 0
   _cTitulo:="Nfs do transportador " + AllTrim(TRBF->COD)+" - "+TRBF->TRANSP
   _cMsgTop:=NIL
   If (_aTotais[7]) > 0
      _cMsgTop:=AllTrim(Str(_aTotais[7]))+" Notas: Valor do Seguro das Nfs"+If(_aTotais[8]<>0," NÃO Geradas","")+" R$ "+AllTrim(TRANSFORM(_aTotais[1],"@E 999,999,999.99"))+;
      If(_aTotais[8]<>0," / Valor do Seguro das Nfs Geradas R$ "+AllTrim(TRANSFORM(_aTotais[8],"@E 999,999,999.99")),"")
   EndIf
// U_ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
   U_ITLISTBOX(_cTitulo, _aCab    , _aLinhas  , .T.      , 4      ,_cMsgTop)
EndIf

If Select("TRBSF2") > 0 
   TRBSF2->(DBSetOrder(1))
EndIf 

Return (Len(_aLinhas) > 0)

/*
===============================================================================================================================
Programa----------: AOMS114 Filtro()
Autor-------------: Alex Wallauer 
Data da Criacao---: 22/07/2019
Descrição---------: Filtro Básico
Parametros--------: _lLerNotas,_lGera
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114Filtro(_lLerNotas,_lGera)

Local cFiltro:=""

// Filtra Filial das tabelas 
If !Empty( xFilial("SF2") )
   cFiltro += " AND SF2.F2_FILIAL = '"+cFilant+"' "
EndIf

If MV_PAR06 = 1//SIM: JÁ EMITIDOS

   If _lLerNotas
      //Filtra transportador posicionado
      cFiltro += " AND SF2.F2_I_CTRA  = '" + TRBF->COD + "' "
      If !Empty(TRBF->F2_I_NDFSE)//SE EM BRANCO É QUE ESTORNOU O FILTRO VAI SER pela tabela: _aRecEsto
          cFiltro += " AND SF2.F2_I_NDFSE = '" + TRBF->F2_I_NDFSE + "' "//CHAVE DOS TIUTLOS
      EndIf   

   Else

      cFiltro += " AND SF2.F2_I_NDFSE <>  ' ' "
      // Filtra Transportadores
      If !Empty(MV_PAR03)
         If Len(AllTrim(MV_PAR03)) > 6
            cFiltro += " AND SF2.F2_I_CTRA IN " + FormatIn(AllTrim(MV_PAR03),";")
         Else
            cFiltro += " AND SF2.F2_I_CTRA = '" + AllTrim(MV_PAR03) + "' "
         EndIf   
      EndIf 

   EndIf 

ElseIf MV_PAR06 = 2//NÃO: NAO EMITIDOS
   If _lLerNotas

      If !Empty(TRBF->F2_I_NDFSE)//DEPOIS QUE GEROU TÁ PREENCHIDO
         cFiltro += " AND SF2.F2_I_NDFSE = '" + TRBF->F2_I_NDFSE + "' "//CHAVE DOS TIUTLOS
      ElseIf _lGera//NA HORA DE GERAR SÓ PEGA OS EM BRANCO
         cFiltro += " AND SF2.F2_I_NDFSE = ' ' "         
      EndIf   
      //Filtra transportador posicionado
      cFiltro += " AND SF2.F2_I_CTRA  = '" + TRBF->COD + "' "

   Else

      cFiltro += " AND SF2.F2_I_NDFSE = ' ' "

      // Filtra Transportadores
      If !Empty(MV_PAR03)
         If Len(AllTrim(MV_PAR03)) > 6
            cFiltro += " AND SF2.F2_I_CTRA IN " + FormatIn(AllTrim(MV_PAR03),";")
         Else
            cFiltro += " AND SF2.F2_I_CTRA = '" + AllTrim(MV_PAR03) + "' "
         EndIf   
      EndIf 

   EndIf

   // Filtra Transportadores por averbacao
   If MV_PAR05 == 1
      cFiltro += " AND SA2.A2_I_AVERB = '1'"
   ElseIf MV_PAR05 == 2
      cFiltro += " AND SA2.A2_I_AVERB = '2'"
   EndIf

   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
      cFiltro+="	AND SA2.A2_I_CLASS IN ('T','A','G') "
   Else
      cFiltro+= "	AND SA2.A2_I_TPFRT = 'S' "//SÓ NA PRODUCAO TESTA
   EndIf   

EndIf

If !Empty(MV_PAR01) 
   cFiltro += " AND SF2.F2_EMISSAO >= '" + DToS(MV_PAR01) + "'"
EndIf  

If !Empty(MV_PAR02) 
   cFiltro += " AND SF2.F2_EMISSAO <= '" + DToS(MV_PAR02) + "'"
EndIf 

If !Empty(MV_PAR04)  
   If Len(AllTrim(MV_PAR04)) > 3
      cFiltro += " 	              AND SD2.D2_LOCAL IN " + FormatIn(AllTrim(MV_PAR04),";")
   Else
      cFiltro += " 	              AND SD2.D2_LOCAL = '"+AllTrim(MV_PAR04)+"' "
   EndIf   
EndIf

Return cFiltro

/*
===============================================================================================================================
Programa----------: AOMS114GE()
Autor-------------: Alex Wallauer 
Data da Criacao---: 22/07/2019
Descrição---------: Le Transportadores marcados para gera os titulos
Parametros--------: oProc,_lEMail,_lGera
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114GE(oProc,_lEMail,_lGera)

Local _nConta:=0
Local _aCab :={} 
Local _aSize:={}
Local _cTot := TRBF->(LASTREC())
Default _lEMail:=.F.
Private _aTLinhas:={}

oProc:cCaption := ("Processando Titulos de Seguro...")
ProcessMessages()

TRBF->(DBGoTop())
While TRBF->(!Eof())
   If _lEMail 
      If !Empty(TRBF->OK) .And. !Empty(TRBF->F2_I_NDFSE)
         _nConta++
      EndIf   
   ElseIf _lGera .And. !Empty(TRBF->OK).AND. Empty(TRBF->F2_I_NDFSE)//GERACAO
      _nConta++
   ElseIf !_lGera .And. !Empty(TRBF->OK) .And. !Empty(TRBF->F2_I_NDFSE) .And. SE2->(DBSeek(xFilial("SE2")+AllTrim(TRBF->F2_I_NDFSE)))//ESTORNO
      _nConta++
   EndIf   
   TRBF->(DBSkip())
EndDo 

If _nConta = 0
   If _lEMail
      U_ITMsg("Nenhum Titulo de Seguro Gerado","Atenção",,1)
   Else
      U_ITMsg("Nenhum registro Marcado","Atenção",,1)
   EndIf   
   Return .F.
EndIf

_cTot:=AllTrim(Str(_nConta))
_nTam:=Len(_cTot)+1
_nConta:=0

SE2->( DBSetOrder(1) ) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

_aRecEsto:={}
TRBF->(DBGoTop())
While TRBF->(!Eof())

   If _lEMail 

      If !Empty(TRBF->OK) .And. !Empty(TRBF->F2_I_NDFSE) .And. SE2->(DBSeek(xFilial("SE2")+AllTrim(TRBF->F2_I_NDFSE)))
         _nConta++
          oProc:cCaption := ("Lendo Titulo: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot+" - Transp.: "+TRBF->COD)
         ProcessMessages()
         _aItens:={}
         aAdd(_aItens,.T.             )     //01
         aAdd(_aItens,SE2->E2_PREFIXO )     //02
         aAdd(_aItens,SE2->E2_NUM     )     //03
         aAdd(_aItens,SE2->E2_PARCELA )     //04
         aAdd(_aItens,SE2->E2_TIPO    )     //05
         aAdd(_aItens,SE2->E2_NATUREZ )     //06
         aAdd(_aItens,SE2->E2_FORNECE )     //07
         aAdd(_aItens,SE2->E2_LOJA    )     //08
         aAdd(_aItens,DToC(SE2->E2_EMISSAO))//09
         aAdd(_aItens,DToC(SE2->E2_VENCTO)) //10
         aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_VALOR,"@E 999,999,999,999.99")))//11
         aAdd(_aItens,SE2->E2_HIST)         //12
         aAdd(_aItens,DToC(SE2->E2_DATALIB))//13
         aAdd(_aItens,SE2->E2_USUALIB)      //14
         aAdd(_aItens,TRBF->QTDENF)         //15
         aAdd(_aItens,"Gerado com Sucesso") //16
         aAdd(_aItens, SE2->(RECNO()) )     //17
         aAdd(_aTLinhas,_aItens)
      EndIf

   ElseIf _lGera .And. !Empty(TRBF->OK) .And. Empty(TRBF->F2_I_NDFSE)//GERACAO
      _nConta++
      oProc:cCaption := ("Gerando Titulo: "+AllTrim(Str(_nConta,_nTam))+" de "+ _cTot+" - Transp.: "+TRBF->COD)
      ProcessMessages()

      AOMS114SE(oProc,AllTrim(Str(TRBF->QTDENF)))//GERACAO

   ElseIf !_lGera .And. !Empty(TRBF->OK) .And. !Empty(TRBF->F2_I_NDFSE) .And. SE2->(DBSeek(xFilial("SE2")+AllTrim(TRBF->F2_I_NDFSE)))//ESTORNO
      _nConta++
      oProc:cCaption := ("Estornando Titulo: "+AllTrim(Str(_nConta,_nTam))+" de "+ _cTot+" - Transp.: "+TRBF->COD)
      ProcessMessages()

      AOM114Estorno(oProc,AllTrim(Str(TRBF->QTDENF)))//ESTORNO

   EndIf   
    
   TRBF->(DBSkip())

EndDo
TRBF->(DBGoTop())

//Monta aheader
aAdd(_aCab,"")//01
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_PREFIXO","X3_TITULO"))//02
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NUM"    ,"X3_TITULO"))//03
aAdd(_aSize,9)
aAdd(_aCab,Getsx3cache("E2_PARCELA","X3_TITULO"))//04
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_TIPO"   ,"X3_TITULO"))//05
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NATUREZ","X3_TITULO"))//06
aAdd(_aSize,8)
aAdd(_aCab,Getsx3cache("E2_FORNECE","X3_TITULO"))//07
aAdd(_aSize,15)
aAdd(_aCab,Getsx3cache("E2_LOJA"   ,"X3_TITULO"))//08	
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_EMISSAO","X3_TITULO"))//09
aAdd(_aSize,15)
aAdd(_aCab,Getsx3cache("E2_VENCTO" ,"X3_TITULO"))//10
aAdd(_aSize,15)
aAdd(_aCab,Getsx3cache("E2_VALOR"  ,"X3_TITULO"))//11
aAdd(_aSize,15)
aAdd(_aCab,Getsx3cache("E2_HIST"   ,"X3_TITULO"))//12
aAdd(_aSize,30)
aAdd(_aCab,Getsx3cache("E2_DATALIB","X3_TITULO"))//13
aAdd(_aSize,15)
aAdd(_aCab,Getsx3cache("E2_USUALIB","X3_TITULO"))//14
aAdd(_aSize,15)
aAdd(_aCab,"Qtde NF")  //15
aAdd(_aSize,10)
aAdd(_aCab,"Resultado")//16
aAdd(_aSize,15)
aAdd(_aCab,"Registro") //17
aAdd(_aSize,10)

If Len(_aTLinhas) > 0

   AOMS114Email(_aTLinhas,_lEMail,oProc,_lGera,_aCab)

   If _lEMail
      Return  .T.
   EndIf   
   nPosResu:=Len(_aCab)//Posiçao do "Resultado"
   nPosRecn:=Len(_aTLinhas[1])//Posiçao do Recno do TRB
   aBotoes:={}                                            //oProc,_cChave,_nRecTRBF                              ,_lGrava,_lSoma
   aAdd( aBotoes , { "" , {|| FWMsgRun(,{ |oProc| AOMS114NF(oProc,""     ,oLbxAux:aArray[oLbxAux:nAt][ nPosRecn ],.F.    ,.T.   )}, "","") },"","Visualiza NFs"} )
   aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Visualizar Erro"		  } )
//    ITListBox(_cTitAux               , _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX("Titulos Processados: ", _aCab    , _aTLinhas , .T.      , 4      ,          ,          , _aSize  ,         ,     ,        , aBotoes)
Else
	U_ITMsg("Nenhum registro localizado","Atenção",,1)
EndIf

Return  .T.
/*
===============================================================================================================================
Programa----------: AOMS114SE()
Autor-------------: Alex Wallauer 
Data da Criacao---: 23/07/2019
Descrição---------: Gera os titulos dos Transportadores marcados
Parametros--------: oProc,_cTot
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114SE(oProc,_cTot) 

Local _nModAux  := nModulo
Local _cModAux  := cModulo
Local _lRet     := .T.  
Local _cNatureza:= SuperGetMV("IT_NDFNATU",.F.,"112006    ")
Local _cCodigo  :="" , nSeq
Local _cFornece :=TRBF->COD
Local _cLoja    :=TRBF->A2_LOJA
Local _nValortit:=TRBF->SEGURO
Local _cHistoric:="SEGURO - "+TRBF->TRANSP
cUserName:=cUserName

SA2->( DBSetOrder(1) ) 
If SA2->(DBSeek(xFilial("SA2")+TRBF->COD+TRBF->A2_LOJA))
	If SA2->A2_MSBLQL == '1'
		SA2->(DBSeek(xFilial("SA2")+TRBF->COD))
		While TRBF->COD == SA2->A2_COD .And. xFilial("SA2") = SA2->A2_FILIAL .And. SA2->(!Eof())
   			If SA2->A2_MSBLQL <> '1'
      			_cLoja:=SA2->A2_LOJA//Pega a primeira loja não bloqueada
      			Exit
   			EndIf
   			SA2->(DBSkip())
		EndDo
	EndIf
EndIf
SE2->( DBSetOrder(1) ) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
For nSeq := 0 To 999
   _cCodigo:=StrZero(nSeq,3)+StrTran( DToC(Date()),"/","")
   If !SE2->(DBSeek(xFilial("SE2")+"MAN"+_cCodigo+"01"+"NDF"))//+_cFornece+_cLoja
      Exit
   EndIf   
Next

_aAutoSE2 := {}
aAdd( _aAutoSE2 , { "E2_PREFIXO"	, "MAN"			, NIL } )		
aAdd( _aAutoSE2 , { "E2_NUM"		, _cCodigo		, NIL } )
aAdd( _aAutoSE2 , { "E2_PARCELA"	, "01"			, NIL } )	
aAdd( _aAutoSE2 , { "E2_TIPO"		, "NDF"			, NIL } )
aAdd( _aAutoSE2 , { "E2_NATUREZ"	, _cNatureza	, NIL } ) 
aAdd( _aAutoSE2 , { "E2_FORNECE"	, _cFornece 	, NIL } )	
aAdd( _aAutoSE2 , { "E2_LOJA"		, _cLoja 		, NIL } )	
aAdd( _aAutoSE2 , { "E2_EMISSAO"	, dDataBase	   , NIL } )   // aAdd( _aAutoSE2 , { "E2_EMISSAO"	, Date()		, NIL } )
aAdd( _aAutoSE2 , { "E2_VENCTO"	, dDtVenc	   , NIL } )
aAdd( _aAutoSE2 , { "E2_VALOR"	, _nValortit   , NIL } )
aAdd( _aAutoSE2 , { "E2_HIST"		, _cHistoric   , Nil } )
aAdd( _aAutoSE2 , { "E2_DATALIB"	, dDataBase		, NIL } )     // aAdd( _aAutoSE2 , { "E2_DATALIB"	, Date()		, NIL } )
aAdd( _aAutoSE2 , { "E2_USUALIB"	, cUserName		, NIL } )
aAdd( _aAutoSE2 , { "E2_ORIGEM"	, "AOMS114"    , NIL } )

_aItens:={}
aAdd(_aItens,.T.     )
aAdd(_aItens,"MAN"   )
aAdd(_aItens,_cCodigo)
aAdd(_aItens,"01"    )
aAdd(_aItens,"NDF"   ) 
aAdd(_aItens,_cNatureza) 
aAdd(_aItens,_cFornece )	
aAdd(_aItens,_cLoja    )		 	
aAdd(_aItens,DToC(dDataBase)) // aAdd(_aItens,DToC(Date()) )
aAdd(_aItens,DToC(dDtVenc) )
aAdd(_aItens,AllTrim(TRANSFORM(_nValortit,"@E 999,999,999,999.99")))//11
aAdd(_aItens,_cHistoric   )
aAdd(_aItens,DToC(dDataBase)) // aAdd(_aItens,DToC(Date()) )
aAdd(_aItens,cUserName    )

nModulo	   := 6
cModulo	   := "FIN"
lMsErroAuto:=.F.
   		  		
MSEXECAUTO({|X,Y| FINA050(X,Y)},_aAutoSE2,3) //Inclusao

_cErro:="Gerado com Sucesso"  		  		
If lMsErroAuto

   _cErro:=(MOSTRAERRO(GETTEMPPATH()))
   _cErro:="Não Gerou. Acesse Visualizar Erro: "+CHR(13)+CHR(10)+AllTrim(_cErro)
   _aItens[1]:=.F.
	_lRet:= .F.  

Else
  _cChave:="MAN"+_cCodigo+"01"+"NDF"+_cFornece+_cLoja
  
  _aTRBF[ TRBF->(RECNO()),01]:=Space(2)
  _aTRBF[ TRBF->(RECNO()),14]:=_cChave
                 //oProc,_cChave,_nRecTRBF      ,_lGrava,_lSoma,lGera
  _cTot:=AOMS114NF(oProc,_cChave,TRBF->(RECNO()),.T.    ,.F.   ,.T.  )//GRAVA O CAMPO F2_I_NDFSE DAS NOTAS
  TRBF->OK        :=Space(2)
  TRBF->F2_I_NDFSE:=_cChave//Grava despois pq causa dos controles do filtro em cima desse campo na gravação
  
EndIf
aAdd(_aItens,_cTot)//15
aAdd(_aItens,_cErro)//16
aAdd(_aItens,TRBF->(RECNO()))//17

aAdd(_aTLinhas,_aItens)

nModulo:= _nModAux
cModulo:= _cModAux

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS114Email()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/07/2019
Descrição---------: Monta e envia email 
Parametros--------: _aTLinhas,_lTela,oProc,_lGera,_aCab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114Email(_aTLinhas,_lTela,oProc,_lGera,_aCab)

Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local _cMsgEml	:= ""
Local nOpcA		:= 2   , _nI , oDlgMail , _aSizes:={}
Local cGetAnx	:= ""
Local cGetCc	:= Space(200)
Local cGetMens	:= Space(999)//Esta é uma mensagem automática
Local cGetPara	:= SuperGetMV("IT_NDFEMAI",.F.,"") + Space(150)
Local _cTot     := AllTrim(Str(Len(_aTLinhas)))
Local _nTam     := Len(_cTot)
Local _cNomeFil := cFilant+" - "+AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_FILIAL') )
Local cGetAssun	:= "Geração de Titulos de Seguro de Frete / "+_cNomeFil+" - ["+DToC(Date())+"]"

If (Len(PSWRET()) # 0) // Quando nao For rotina automatica do configurador
   PswOrder(1)
   PswSeek(__cUserId,.T.)
   aUsuario:= PswRet()
   cGetCc  := LOWER(AllTrim(aUsuario[1,14]))+Space(150)// Pega e-mail do usuario
EndIf
If Empty(cGetPara)
   cGetPara:=cGetCc
EndIf   
_cMsgEml := '<html>'
If _lGera
  _cMsgEml += '<head><title>Geração de Titulos de Seguro de Frete</title></head>'
Else
   cGetAssun:= "Estorno de Titulos de Seguro de Frete / "+_cNomeFil+" - ["+DToC(Date())+"]"
  _cMsgEml += '<head><title>Estorno de Titulos de Seguro de Frete</title></head>'
EndIf
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cGetAssun+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados de envio</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Enviado por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Observações:</b></td>'
_cMsgEml += '      <td class="itens" >#OBS#</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1200">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="9" class="grupos">Titulos de Seguro de Frete</b></td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
//        02   03   04   05    06   07   08   09   10   11   12   13   14
_aSizes:={"4","7","4","4","  ","  ","  ","7","7","7","50","  ","10"}
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[02]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCab[03]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>'+_aCab[04]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%"><b>'+_aCab[05]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[08]+'%"><b>'+_aCab[09]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[09]+'%"><b>'+_aCab[10]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[10]+'%"><b>'+_aCab[11]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[11]+'%"><b>Codigo-Loja / Historico</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[13]+'%"><b>'+_aCab[14]+'</b></td>'

_cMsgEml += '    </tr>'

_cMsgEml += '    #LISTA#'

_cMsgEml += '</table>'
	
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [AOMS114]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

If _lTela

   oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo

   DEFINE MSDIALOG oDlgMail TITLE "E-Mail de: "+Lower(AllTrim(UsrRetMail(RetCodUsr()))) FROM 000, 000  To 415,999 COLORS 0, 16777215 PIXEL
     _nLinha:=05
     _nPula :=16
     _nWidth:=((oDlgMail:nClientWidth-6)/2)-8
     _nSize :=_nWidth-24
	@ _nLinha+2, 005 Say "Para:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetPara SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
     _nLinha+=_nPula
	@ _nLinha+2, 005 Say "Cc:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetCc SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
     _nLinha+=_nPula
	@ _nLinha+2, 005 Say "Assunto:" SIZE 022, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetAssun SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
     _nLinha+=_nPula
	@ _nLinha+2, 005 Say "Observ.:" SIZE 030, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetMens SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
     _nLinha+=_nPula

	// LISTA
  //TCBrowse():New( [ nRow ], [ nCol ], [ nWidth ], [ nHeight ], [ bLine ], [ aHeaders ], [ aColSizes ], [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ]  , [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
	oMark2:= TCBrowse():New(070 , 006  ,_nWidth , 110  ,          ,             ,              , oDlgMail ,           ,            ,            ,            ,                 ,            ,          ,            ,             ,             ,         ,    .F.      ,           ,   .T.     ,          ,    .F.      ,           ,             ,              )
	oMark2:SetArray(_aTLinhas)
  	oMark2:AddColumn(TCColumn():New(_aCab[01],{|| LoadBitmap(GetResources(), If(_aTLinhas[oMark2:nat,01],"BR_VERDE","BR_VERMELHO")) },,,,,,.T.,.F.,,,,.F., ) )
	oMark2:AddColumn(TCColumn():New(_aCab[02],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,02], ' ') },"@!"       	,,,"LEFT" ,020,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[03],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,03], ' ') },"@!"       	,,,"LEFT" ,020,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[04],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,04], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[05],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,05], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[06],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,06], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[07],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,07], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[08],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,08], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[09],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,09], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[10],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,10], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[11],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,11], ' ') },"@!"        ,,,"RIGHT",050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[12],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,12], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[13],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,13], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[14],{|| IIf(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,14], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	                                     
	@ 189, 005 BUTTON "ENVIAR"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , oDlgMail:End() ) PIXEL
	@ 189, 050 BUTTON "CANCELAR"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

   ACTIVATE MSDIALOG oDlgMail CENTERED

Else
   cGetMens:="Esta é uma mensagem automática"
EndIf   

If nOpcA == 1 .Or. !_lTela

   _cMsgEml:=StrTran(_cMsgEml,"#OBS#",cGetMens)
   _cGetLista:=""
   _lEnvia:=.F.
   For _nI := 1 To Len(_aTLinhas)
	   oProc:cCaption := ("Lendo dados dos Titulo: "+AllTrim(Str(_nI,_nTam))+" de "+ _cTot)
       ProcessMessages()
       If !_aTLinhas[_nI,01]
          Loop
       EndIf
	   _cGetLista += '    <tr>'
	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+ _aTLinhas[_nI][02]+'</td>'
	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ _aTLinhas[_nI][03]+'</td>'
	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[03]+'%">'+ _aTLinhas[_nI][04]+'</td>'
  	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[04]+'%">'+ _aTLinhas[_nI][05]+'</td>'
	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[08]+'%">'+ _aTLinhas[_nI][09]+'</td>'
	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[09]+'%">'+ _aTLinhas[_nI][10]+'</td>'
	   _cGetLista += '      <td class="itens" align="right" width="'+_aSizes[10]+'%">'+ _aTLinhas[_nI][11]+'</td>'
	   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[11]+'%">'+ _aTLinhas[_nI][07]+"-"+_aTLinhas[_nI][08]+" / "+_aTLinhas[_nI][12]+'</td>'
	   _cGetLista += '      <td class="itens" align="center" width="'+_aSizes[13]+'%">'+ _aTLinhas[_nI][14]+'</td>'
	   _cGetLista += '    </tr>'
	   _lEnvia:=.T.
   Next
   
	If _lEnvia
		
		_cMsgEml:=StrTran(_cMsgEml,"#LISTA#",_cGetLista)
		
		// Chama a função para envio do e-mail
		U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, "", cGetAssun, _cMsgEml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
		U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
		"E-mail para: "+cGetPara +CHR(13)+CHR(10)+;
		"Com Copia: "+cGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)

	EndIf
   
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOM114Trava()
Autor-------------: Alex Wallauer 
Data da Criacao---: 31/07/2019
Descrição---------: Travaa tela para um usuario por filial
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function AOM114Trava()

Local _nCnt01  	:= 0
Local _lLockZP1	:= .F.

DBSelectArea( "ZP1" )
ZP1->( DBSetOrder(2) )
If ZP1->( MsSeek( xFilial('ZP1') + cFilant + _cMV_ZP1 ) )//TRAVA POR FILIAL
   While !_lLockZP1 .And. (++_nCnt01 < 03)
	  If InTransact()
	  	_lLockZP1 := RecLock("ZP1")
	  Else
	 	_lLockZP1 := MsRLock()
	  EndIf
	  If !_lLockZP1
	     Inkey(1)
	  EndIf
   EndDo
Else
   ZP1->(RecLock("ZP1",.T.))
   ZP1->ZP1_FILIAL:=xFilial("ZP1")
   ZP1->ZP1_MODULO:="39"
   ZP1->ZP1_GRUPO :="P"
   ZP1->ZP1_ROTINA:="AOMS114"
   ZP1->ZP1_DESROT:="Central de seguros de frete"
   ZP1->ZP1_FILPAR:=cFilant
   ZP1->ZP1_PARAM :=_cMV_ZP1
   ZP1->ZP1_DESCRI:="Trava por filial + usuario do Programa AOMS114"
   ZP1->ZP1_TIPO  :="C"
   _lLockZP1:=.T.
EndIf
ZP1->( DBSetOrder(1) )
If _lLockZP1
   ZP1->ZP1_CONTEU:=UsrFullName(__cUserId)+" - "+DToC(Date())+" - "+Time()
Else
   U_ITMsg( "O Programa esta sendo utilizado pelo Usuario: "+AllTrim(ZP1->ZP1_CONTEU),"Parametro "+_cMV_ZP1+" na ZP1","Aguarde o usuario finalizar",1) 
   Return .F.
EndIf

If MV_PAR01 < _dDtCorte .Or. MV_PAR01 > MV_PAR02
   U_ITMsg("Intervalo de datas invalido","Parametro ITNDFDTCOR na ZP1","Data inicial deve ser maior ou igual que data de Corte: "+DToC(_dDtCorte),1) 
   Return .F.
EndIf

Return .T.
/*
===============================================================================================================================
Programa----------: AOM114Estorno()
Autor-------------: Alex Wallauer 
Data da Criacao---: 31/07/2019
Descrição---------: Estorna Titulo do seguro
Parametros--------: oProc,_cTot
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function AOM114Estorno(oProc,_cTot)

Local _aAutoSE2:= {}
Local _nModAux  := nModulo
Local _cModAux  := cModulo
Local _lRet     := .T.  
					
aAdd( _aAutoSE2 , { "E2_FILIAL"		, SE2->E2_FILIAL		, nil } )	
aAdd( _aAutoSE2 , { "E2_PREFIXO"	, SE2->E2_PREFIXO		, nil } )		
aAdd( _aAutoSE2 , { "E2_NUM"		, SE2->E2_NUM			, nil } )
aAdd( _aAutoSE2 , { "E2_PARCELA"	, SE2->E2_PARCELA		, nil } )	
aAdd( _aAutoSE2 , { "E2_TIPO"		, SE2->E2_TIPO			, nil } )
aAdd( _aAutoSE2 , { "E2_NATUREZ"	, SE2->E2_NATUREZ		, nil } ) 
aAdd( _aAutoSE2 , { "E2_FORNECE"	, SE2->E2_FORNECE		, nil } )	
aAdd( _aAutoSE2 , { "E2_LOJA"		, SE2->E2_LOJA			, nil } )	
aAdd( _aAutoSE2 , { "E2_EMISSAO"	, SE2->E2_EMISSAO		, nil } )
aAdd( _aAutoSE2 , { "E2_VENCTO"	, SE2->E2_VENCTO		, nil } )
aAdd( _aAutoSE2 , { "E2_VALOR"	, SE2->E2_VALOR		, nil } )
aAdd( _aAutoSE2 , { "E2_HIST"		, SE2->E2_HIST 		, Nil } )
aAdd( _aAutoSE2 , { "E2_DATALIB"	, SE2->E2_DATALIB		, nil } )
aAdd( _aAutoSE2 , { "E2_USUALIB"	, SE2->E2_USUALIB		, nil } )

_aItens:={}
aAdd(_aItens,.T.)
aAdd(_aItens,SE2->E2_PREFIXO)
aAdd(_aItens,SE2->E2_NUM)
aAdd(_aItens,SE2->E2_PARCELA)
aAdd(_aItens,SE2->E2_TIPO) 
aAdd(_aItens,SE2->E2_NATUREZ) 
aAdd(_aItens,SE2->E2_FORNECE)	
aAdd(_aItens,SE2->E2_LOJA   )		 	
aAdd(_aItens,DToC(SE2->E2_EMISSAO))
aAdd(_aItens,DToC(SE2->E2_VENCTO))
aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_VALOR,"@E 999,999,999,999.99")))//11
aAdd(_aItens,SE2->E2_HIST   )
aAdd(_aItens,DToC(SE2->E2_DATALIB))
aAdd(_aItens,SE2->E2_USUALIB)
   
nModulo	   := 6
cModulo	   := "FIN"
lMsErroAuto:=.F.

MSExecAuto({|v,h,k,l,m,n,o| Fina050(v,h,k,l,m,n,o)},_aAutoSE2,,5,,,.F.,.T.)//Exclusão

_cErro:="Estornado com Sucesso"  		  		
If lMsErroAuto

   _cErro:=(MOSTRAERRO(GETTEMPPATH()))
   _cErro:="Não Estornou. Acesse Visualizar Erro: "+CHR(13)+CHR(10)+_cErro
   _aItens[1]:=.F.

Else

  _aTRBF[ TRBF->(RECNO()),01]:=Space(2)
  _aTRBF[ TRBF->(RECNO()),14]:=""
                 //oProc,_cChave         ,_nRecTRBF      ,_lGrava,_lSoma,lGera
  _cTot:=AOMS114NF(oProc,TRBF->F2_I_NDFSE,TRBF->(RECNO()),.T.    ,.F.   ,.F.  )//LIMPA O CAMPO F2_I_NDFSE DAS NOTAS
  TRBF->OK        :=Space(2)
  TRBF->F2_I_NDFSE:=""//Limpa despois pq causa dos controles do filtro em cima desse campo no estorno
  
EndIf
aAdd(_aItens,_cTot)//15
aAdd(_aItens,_cErro)//16
aAdd(_aItens,TRBF->(RECNO()))//17

aAdd(_aTLinhas,_aItens)

nModulo:= _nModAux
cModulo:= _cModAux

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS11 4B()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/06/2021
Descrição---------: Cria tabela temporária e carrega com os dados das notas fiscais selecionadas nos filtros.
Parametros--------: _oProc - objeto da regua de processamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS114B(_oProc,QRYNFS)

Local _aStruct := {}
Local _nPerTransp, _nPSeguro
   
If Select("TRBSF2") = 0
   _oProc:cCaption := ("Criando arquivo detalhes das notas...")
   ProcessMessages()

   aAdd(_aStruct,{"WK_OK"     ,"C",2,0})
   aAdd(_aStruct,{"F2_FILIAL" ,"C",2,0})
   aAdd(_aStruct,{"F2_DOC"    ,"C",Getsx3cache("F2_DOC","X3_TAMANHO"),0})
   aAdd(_aStruct,{"F2_SERIE"  ,"C",Getsx3cache("F2_DOC","X3_TAMANHO"),0})
   aAdd(_aStruct,{"F2_EMISSAO","D",8,0})
   aAdd(_aStruct,{"A2_I_AVERB",Getsx3cache("A2_I_AVERB","X3_TIPO"), Getsx3cache("A2_I_AVERB","X3_TAMANHO"),Getsx3cache("A2_I_AVERB","X3_DECIMAL")})
   aAdd(_aStruct,{"A2_COD"    ,"C",Getsx3cache("A2_COD","X3_TAMANHO"),0})   
   aAdd(_aStruct,{"A2_LOJA"   ,"C",Getsx3cache("A2_LOJA","X3_TAMANHO"),0}) 
   aAdd(_aStruct,{"A2_EST"    ,"C",Getsx3cache("A2_EST","X3_TAMANHO"),0}) 
   aAdd(_aStruct,{"A2_NREDUZ" ,"C",Getsx3cache("A2_NREDUZ","X3_TAMANHO"),0}) 
   aAdd(_aStruct,{"F2_I_NDFSE","C", Getsx3cache("F2_I_NDFSE","X3_TAMANHO"),0}) // Nota Fiscal do Seguro
   aAdd(_aStruct,{"F2_I_FRET" ,"N",Getsx3cache("F2_I_FRET","X3_TAMANHO"),Getsx3cache("F2_I_FRET","X3_DECIMAL")}) 
   aAdd(_aStruct,{"F2_VALMERC","N",Getsx3cache("F2_VALMERC","X3_TAMANHO"),Getsx3cache("F2_VALMERC","X3_DECIMAL")}) 
   aAdd(_aStruct,{"F2_VALBRUT","N",Getsx3cache("F2_VALBRUT","X3_TAMANHO"),Getsx3cache("F2_VALBRUT","X3_DECIMAL")}) 
   aAdd(_aStruct,{"WK_PERSEGU","N",14,8}) 
   aAdd(_aStruct,{"WK_SEGURO" ,"N",18,6}) 
   aAdd(_aStruct,{"F2_I_CTRA" ,"C",Getsx3cache("F2_I_CTRA","X3_TAMANHO"),0})   // Transportadora
   aAdd(_aStruct,{"F2_I_LTRA" ,"C",Getsx3cache("F2_I_LTRA","X3_TAMANHO"),0})   // Loja Transportadora
   aAdd(_aStruct,{"WK_RECNO"  ,"C",10,0})
   aAdd(_aStruct,{"WK_RECSF2" ,"C",10,0})

   _oTRBSF2 := FWTemporaryTable():New( "TRBSF2", _aStruct )
   _oTRBSF2:AddIndex( "1", {"WK_RECNO"} )
   _oTRBSF2:AddIndex( "2", {"WK_RECSF2"} )

   _oTRBSF2:Create()
EndIf
_nPerTransp := Posicione('ZGX',1,xFilial("ZGX")+(QRYNFS)->F2_FILIAL+(QRYNFS)->TRANSPORT+(QRYNFS)->LOJATRANSP,'ZGX_PERSEG')
If ! Empty(_nPerTransp)
   _nPSeguro := (_nPerTransp/100)
Else
   _nPSeguro := _nPercSeguro
EndIf 

TRBSF2->(DBAPPEND())
TRBSF2->WK_OK      := _cMarca
TRBSF2->F2_FILIAL  := (QRYNFS)->F2_FILIAL
TRBSF2->F2_DOC     := (QRYNFS)->F2_DOC
TRBSF2->F2_SERIE   := (QRYNFS)->F2_SERIE
TRBSF2->F2_EMISSAO := (QRYNFS)->F2_EMISSAO
TRBSF2->A2_I_AVERB := (QRYNFS)->A2_I_AVERB
TRBSF2->A2_COD     := (QRYNFS)->A2_COD
TRBSF2->A2_LOJA    := (QRYNFS)->A2_LOJA
TRBSF2->A2_EST     := (QRYNFS)->A2_EST
TRBSF2->A2_NREDUZ  := (QRYNFS)->A2_NREDUZ
TRBSF2->F2_I_NDFSE := (QRYNFS)->F2_I_NDFSE
TRBSF2->F2_I_FRET  := (QRYNFS)->F2_I_FRET
TRBSF2->F2_VALMERC := (QRYNFS)->F2_VALMERC
TRBSF2->F2_VALBRUT := (QRYNFS)->F2_VALBRUT
TRBSF2->F2_I_CTRA  := (QRYNFS)->TRANSP
TRBSF2->F2_I_LTRA  := (QRYNFS)->LOJATRANSP
TRBSF2->WK_SEGURO  := (QRYNFS)->F2_VALBRUT * _nPSeguro
TRBSF2->WK_PERSEGU := _nPSeguro * 100
TRBSF2->WK_RECNO   := StrZero( TRBF->(Recno()) ,10) // Grava o Recno da tabela TRBF
TRBSF2->WK_RECSF2  := StrZero((QRYNFS)->SF2_REC,10) 

Return

/*
===============================================================================================================================
Programa----------: AOMS114R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/06/2021
Descrição---------: Permite selecionar as notas fiscais que serão utilizadas na geração dos titulos de seguro.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS114R()

Local _nHeight		:= 0
Local _nWidth		:= 0
Local _aSize			:= {}
Local _aBotoes		:= {}
Local _nOpca  := 0
Local _cChavePesq 

Private _oMark	
Private _oQtdNfs
Private _oValorSeg
Private _aNotas := {}
Private _nQtdNfs, _nValSegNf
Private _oPanelSF2
Private _oDlgNfs

Begin Sequence 
   // Carrega os dados das notas fiscais no array _aNotas.
   _nQtdNfs := 0
   _nValSegNf := 0

   TRBSF2->(DBSetOrder(1))
   _cChavePesq := StrZero(_aTRBF[oMark:NAT,15],10)
   TRBSF2->(MsSeek(_cChavePesq))
   While ! TRBSF2->(Eof()) .And. _cChavePesq == TRBSF2->WK_RECNO
      aAdd(_aNotas,{TRBSF2->WK_OK,;                                // 1
                    TRBSF2->F2_FILIAL,;                            // 2
                    TRBSF2->F2_DOC,;                               // 3
                    TRBSF2->F2_SERIE,;                             // 4
                    TRBSF2->F2_EMISSAO,;                           // 5
                    If(TRBSF2->A2_I_AVERB=="1","Sim","Não"),;      // 6
                    TRBSF2->A2_COD,;                               // 7
                    TRBSF2->A2_LOJA,;                              // 8
                    TRBSF2->A2_NREDUZ,;                            // 9  
                    TRBSF2->A2_EST,;                               // 10
                    TRBSF2->F2_I_NDFSE,;                           // 11
                    TRBSF2->F2_VALMERC,;                           // 12
                    TRBSF2->F2_I_FRET,;                            // 13
                    TRBSF2->F2_VALBRUT,;                           // 14
                    TRBSF2->F2_I_CTRA,;                            // 15  
                    TRBSF2->F2_I_LTRA,;                            // 16
                    TRBSF2->WK_PERSEGU,; // "% seguro "            // 17  
                    TRBSF2->WK_SEGURO,;  // "Valor do Seguro"      // 18
                    TRBSF2->WK_RECNO,;                             // 19 
                    TRBSF2->(Recno())})                            // 20

      If ! Empty(TRBSF2->WK_OK)              
         _nQtdNfs += 1
         _nValSegNf += TRBSF2->WK_SEGURO
      EndIf 
      TRBSF2->(DBSkip())
   EndDo 
   
   _nValSegNf := Round(_nValSegNf,2)

   // Botoes da tela.
   aAdd( _aBotoes , { "" , {|| U_AOMS114M("T") }   , "" , "Marca/Desmarca Todos"} )

   // Faz o calculo automatico de dimensoes da tela do computador
   _aSize := MSADVSIZE() 

   _nOpca:= 2
   DEFINE MSDIALOG _oDlgNfs TITLE "Seleção de Notas para Geração dos Títulos" From 0,0 To _aSize[6],_aSize[5] PIXEL

	_oPanelSF2:= TPanel():New(30,0,'',_oDlgNfs,, .T., .T.,, ,315,20,.T.,.T. )
	oFont := TFont():New('Times New Roman',,-16,.T.)

	_nCol:=005
	_nSize:=60
	_nPula:=70
   
   @ 003,_nCol BUTTON "Marca/Desmarca Todos" SIZE _nSize, 015 PIXEL OF _oPanelSF2 ACTION (U_AOMS114M("T"))
   _nCol+=_nPula

   _oQtdNfs := TSay():New(05,_nCol,{||'Qtde Notas: '+AllTrim(TRANSFORM(_nQtdNfs,"@E 99,999,999,999"))},_oPanelSF2,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)//450
	_nCol+=_nPula

	_oValorSeg := TSay():New(05,_nCol,{||'Valor seguro: '+AllTrim(TRANSFORM(_nValSegNf,"@E 999,999,999.99"))},_oPanelSF2,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)//550
	
	If FlatMode()
		aCoors	:= GetScreenRes()
		_nHeight	:= aCoors[2]
		_nWidth	:= aCoors[1]
	Else
		_nHeight	:= 143
		_nWidth	:= 315
	EndIf

  //TCBrowse():New( [ nRow ], [ nCol ], [ _nWidth ], [ _nHeight ], [ bLine ], [ aHeaders ], [ aColSizes ], [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ]  , [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
	_oMark := TCBrowse():New(35,  01   , 35+_nHeight, 01+_nWidth  ,          ,             ,              , _oDlgNfs   ,           ,            ,            ,            ,                 ,            ,          ,            ,             ,             ,         ,    .F.      ,           ,   .T.     ,          ,    .F.      ,           ,             ,              )

	_oMark:SetArray(_aNotas)
	_oMark:bLDblClick   := {|| U_AOMS114M("P")}
	
	_oMark:AddColumn(TCColumn():New(" "       	   	 ,{|| LoadBitmap(GetResources(), If(Len(_aNotas)>0,If(_aNotas[_oMark:nat,01]==_cMarca,"LBOK","LBNO"),"LBNO") ) },,,,,,.T.,.F.,,,,.F., ) )
  	_oMark:AddColumn(TCColumn():New("Filial"            ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,02], ' ') },"@!"       			  ,,,"LEFT" ,010,.F.,.F.,,,,,))
	_oMark:AddColumn(TCColumn():New("Nota Fiscal"		 ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,03], ' ') },"@!"       			  ,,,"LEFT" ,20,.F.,.F.,,,,,))
	_oMark:AddColumn(TCColumn():New("Serie"		       ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,04], ' ') },"@!"       			  ,,,"LEFT" ,6,.F.,.F.,,,,,))
	_oMark:AddColumn(TCColumn():New("Emissão"		       ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,05], ' ') },"@D"       			  ,,,"CENTER" ,10,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Averbação"		    ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,06], ' ') },"@!"       			  ,,,"LEFT" ,10,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Fornecedor"		    ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,07], ' ') },"@!"       			  ,,,"LEFT" ,10,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Loja Forn."		    ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,08], ' ') },"@!"       			  ,,,"LEFT" ,10,.F.,.F.,,,,,))
	_oMark:AddColumn(TCColumn():New("Nome"		          ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,09], ' ') },"@!"       			  ,,,"LEFT" ,20,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Estado"		       ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,10], ' ') },"@!"       			  ,,,"LEFT" ,6,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Nota Fiscal Seguro",{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,11], ' ') },"@!"       			  ,,,"LEFT" ,30,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Valor Mercadoria"	 ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,12], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("Frete" 				 ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,13], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
	_oMark:AddColumn(TCColumn():New("Valor Bruto" 		 ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,14], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
   _oMark:AddColumn(TCColumn():New("% Seguro" 			 ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,17], ' ') },"@E 99,999,999,999.999",,,"RIGHT",050,.F.,.F.,,,,,))
	_oMark:AddColumn(TCColumn():New("Seguro" 			    ,{|| If(Len(_aNotas)>0,_aNotas[_oMark:nat,18], ' ') },"@E 999,999,999,999.99",,,"RIGHT",050,.F.,.F.,,,,,))
		
	_oDlgNfs:lMaximized:=.T.

   Activate MSDIALOG _oDlgNfs ON INIT ( EnchoiceBar(_oDlgNfs,{|| If(U_AOMS114V(),(_nOpca:= 1,_oDlgNfs:End()),_nOpca:= 2) },;
                                                       {|| _nOpca:= 2,_oDlgNfs:End() },,_aBotoes),;
                                     _oPanelSF2:Align:=CONTROL_ALIGN_TOP ,;
                                     _oMark:Align:=CONTROL_ALIGN_ALLCLIENT ,;
                                     _oMark:Refresh())
    If _nOpca = 1
       nValTit-=TRBF->SEGURO//Tira o valor ANTERIOR
       
       TRBF->(DBGoTo(_aTRBF[oMark:NAT,15]))
       TRBF->(RecLock("TRBF",.F.))
       TRBF->QTDENF := _nQtdNfs
       TRBF->SEGURO := _nValSegNf
       TRBF->(MSUnLock())
       
       nValTit+=TRBF->SEGURO//Coloca o valor ATUAL

       _aTRBF[oMark:NAT,10] := _nQtdNfs 
       _aTRBF[oMark:NAT,13] := _nValSegNf
    EndIf

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AOMS114R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/06/2021
Descrição---------: Marca e desmar itens. Posicionado ou todos.
Parametros--------: _cTipoMarca = "P" = Marca e desmarca apenas o Item posicionado.
                                  "T" = Marca e desmarca todos os itens.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS114M(_cTipoMarca)

Local _nI 
Local _lMarcar := .T.
Local _cMarkSF2 
Local _nItens, _nTotSegur

// Marca/desmarca apenas o item posicionado.
If _cTipoMarca == "P"
   If Empty(_aNotas[_oMark:nat,01])
      TRBSF2->(DBGoTo(_aNotas[_oMark:nat,20]))
      TRBSF2->(RecLock("TRBSF2",.F.))
      TRBSF2->WK_OK :=_cMarca                     
      TRBSF2->(MSUnLock())
      _aNotas[_oMark:nat,01] := _cMarca
   Else
      TRBSF2->(DBGoTo(_aNotas[_oMark:nat,20]))
      TRBSF2->(RecLock("TRBSF2",.F.))
      TRBSF2->WK_OK := Space(2)                     
      TRBSF2->(MSUnLock())
      _aNotas[_oMark:nat,01] := Space(2)
   EndIf 
Else
   // Marca/desmarca todos os itens
   For _nI := 1 To Len(_aNotas)
         If ! Empty(_aNotas[_nI,01])  
            _lMarcar := .F.
         EndIf 
   Next 
   
   If _lMarcar
      _cMarkSF2 := _cMarca 
   Else
      _cMarkSF2 := Space(2)
   EndIf 

   For _nI := 1 To Len(_aNotas)
         TRBSF2->(DBGoTo(_aNotas[_nI,20]))
         TRBSF2->(RecLock("TRBSF2",.F.))
         TRBSF2->WK_OK := _cMarkSF2
         TRBSF2->(MSUnLock())
         _aNotas[_nI,01] := _cMarkSF2
   Next 

EndIf 

_nItens := 0
_nTotSegur := 0

For _nI := 1 To Len(_aNotas)
      If ! Empty(_aNotas[_nI,01])
         _nItens += 1
         _nTotSegur += _aNotas[_nI,18] 
      EndIf 
Next 

_nQtdNfs := _nItens 
_oQtdNfs:SetText('Qtde Notas: '+AllTrim(TRANSFORM(_nQtdNfs,"@E 99,999,999,999")))
_oQtdNfs:CtrlRefresh()

_nValSegNf := _nTotSegur
_oValorSeg:SetText('Valor seguro: '+AllTrim(TRANSFORM(_nValSegNf,"@E 999,999,999.99")))
_oValorSeg:CtrlRefresh()

Return 

/*
===============================================================================================================================
Programa----------: AOMS114V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/06/2021
Descrição---------: Valida a Gravação do valor das notas selecionadas para geração de titulos de seguros.
Parametros--------: Nenhum
Retorno-----------: _lRet = .T. validação correta.
                            .F. Problema encontrados na validação.
===============================================================================================================================
*/
User Function AOMS114V()

Local _lRet := .T.
Local _nI, _lTemNf 

Begin Sequence
    If ! U_ITMsg("Confirma a atualização dos valores de titulos de seguros a serem gerados, com base no valor do seguro das notas fiscais selecionadas?",;
               "Atenção", , ,2, 2)
       _lRet := .F.
       Break
    EndIf 
    
    _lTemNf := .F.
    For _nI := 1 To Len(_aNotas)
        If ! Empty(_aNotas[_nI,01])
           _lTemNf := .T.
           Exit 
        EndIf 
    Next 

    If ! _lTemNf  
       U_ITMsg("Nenhuma nota fiscal foi selecionada.","Atenção","Selecione pelo menos uma nota fiscal, ou desmarque a geração de tiluos para esta transportadora.",1) 
       _lRet := .F.
       Break
    EndIf
End Sequence

Return _lRet 
