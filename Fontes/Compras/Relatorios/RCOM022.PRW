/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |10/04/2024| Chamado 46749. Adicioando a tratativa para produtos que mudam de código entre filiais. 
Antonio Neves |20/04/2024| Chamado 46749. Adicioando a tratativa para produtos que mudam de código entre filiais. 
Alex Wallauer |20/09/2024| Chamaod 48579. Corrigir o relatório RCOM022, quando um item repete em duas linhas na mesma nota.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa.........: RCOM022
Autor............: Alex Wallauer
Data da Criacao..: 23/02/2024
Descricao........: Chamado 46294. André. Relatorio de Transferencias entre filiais.
Parametros.......: Nenhum
Retorno..........: Nenhum
===============================================================================================================================
*/
User Function RCOM022()
	Local  nI

	_aOpcoes:={"1-Em transito","2-Ja recebidas","3-Todos"}
	_aOrdem :={"1-Produto        ",;
		       "2-Documento/Serie",;
		       "3-Data de emissao"}

	MV_PAR01:=Space(200)  //FILIAL ORIGEM
	MV_PAR02:=Space(200)  //FILIAL DESTINO
	MV_PAR03:=dDataBase   //DATA DE EMISSAO DE
	MV_PAR04:=dDataBase   //DATA DE EMISSAO ATE
	MV_PAR05:=Space(009)  //DOC SAIDA DE
	MV_PAR06:=Space(009)  //DOC SAIDA ATE
	MV_PAR07:=Space(003)  //SER DOC SAIDA DE
	MV_PAR08:=Space(003)  //SER DOC SAIDA ATE
	MV_PAR09:=Space(015)  //PRODUTO DE
	MV_PAR10:=Space(015)  //PRODUTO ATE
	MV_PAR11:=Space(200)  //GRUPO DE PRODUTOS
	MV_PAR12:=Val(_aOpcoes[3]) //LISTA NFS EM TRANSITO/JA RECEBIDAS/TODAS
	MV_PAR13:=_aOrdem[1] //aOrdem
	_aParAux:={}
	aAdd( _aParAux , { 1 , "Filial Origem"      , MV_PAR01, "@!"  , ""  ,"LSTFIL", "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Filial Destino"     , MV_PAR02, "@!"  , ""  ,"LSTFIL", "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Data Emissao de"    , MV_PAR03, "@D"  , ""  ,""      , "" , 050 , .T. } )
	aAdd( _aParAux , { 1 , "Data Emissao ate"   , MV_PAR04, "@D"  , ""  ,""      , "" , 050 , .T. } )
	aAdd( _aParAux , { 1 , "Doc saida de"       , MV_PAR05, "@!"  , ""  ,""      , "" , 050 , .F. } )
	aAdd( _aParAux , { 1 , "Doc saida ate"      , MV_PAR06, "@!"  , ""  ,""      , "" , 050 , .F. } )
	aAdd( _aParAux , { 1 , "Serie Doc saída de" , MV_PAR07, "@!"  , ""  ,""      , "" , 050 , .F. } )
	aAdd( _aParAux , { 1 , "Serie Doc saida ate", MV_PAR08, "@!"  , ""  ,""      , "" , 050 , .F. } )
	aAdd( _aParAux , { 1 , "Produto de"         , MV_PAR09, "@!"  , ""  ,"SB1"   , "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Produto ate"        , MV_PAR10, "@!"  , ""  ,"SB1"   , "" , 100 , .F. } )
	aAdd( _aParAux , { 1 , "Grupo de Produtos"  , MV_PAR11, "@!"  , ""  ,"LSTSBM", "" , 100 , .F. } )
	aAdd( _aParAux , { 3 , "Lista NFs"          , MV_PAR12, _aOpcoes                  , 100 , "",.T.,.T.,.T.} )
	aAdd( _aParAux , { 3 , "Ordenar por"        , MV_PAR13, _aOrdem                   , 100 , "",.T.,.T.,.T.} )

	_aParRet:={}
	For nI := 1 To Len( _aParAux )
		aAdd( _aParRet , _aParAux[nI][03] )
	Next

	cTitle:="Relatorio de Transferencias entre filiais"
	While .T.
		//aParametros, cTitle , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ]
		If !ParamBox( _aParAux , cTitle , @_aParRet,     , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
			Return .F.
		EndIf
		_aAcesso:= {}
		cTimeInicial:=Time()

		FWMsgRun( ,{|| _aAcesso:= FWEmpLoad(.F.) } , "Lendo Acessos de filiais - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

		If !ValFilial(@MV_PAR01,"Filial Origem" )
			Loop
		EndIf
		If !ValFilial(@MV_PAR02,"Filial Destino")
			Loop
		EndIf

		If !(MV_PAR04 >= MV_PAR03)
			U_ITMsg("Periodo da Data de Emissao INVALIDO",'Atenção!',"Tente novamente com outro periodo",1)
			Loop
		EndIf

		If ValType(MV_PAR12) = "N"
			MV_PAR12:=Str(MV_PAR12,1)
		EndIf
		If ValType(MV_PAR13) = "N"
			MV_PAR13:=Str(MV_PAR13,1)
		EndIf

		cTimeInicial:=Time()

		FWMsgRun( ,{|oProc| RCOM022R(oProc) } , "Lendo Dados - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

	EndDo

Return(.T.)
/*
===============================================================================================================================
Programa.........: RCOM022R
Autor............: Alex Wallauer
Data da Criacao..: 23/02/2024
Descricao........: Leitura dos dados selecinados.
Parametros.......: oProc
Retorno..........: Nenhum
===============================================================================================================================
*/
Static Function RCOM022R(oProc)
Local aFilsCalc  := {}  , L               			// Array com dados das filiais
Local aAreaSM0   := SM0->(GetArea()) 				// Status original do arquivo SM0
Local cFilBack   := cFilAnt           		 		// Filial corrente original
Local lUsaFilTrf := UsaFilTrf()
Local _aDados := {}

U_ITLOGACS("RCOM022")

SB1->(DBSetOrder(1))
SF4->(DBSetOrder(1))

If MV_PAR13 = "1" // Ordem por produto 
	SD2->(DBSetOrder(1))
ElseIf MV_PAR13 = "2" // Ordem de documento
	SD2->(DBSetOrder(3))
ElseIf MV_PAR13 = "3" // Ordem de data
	SD2->(DBSetOrder(5))      
EndIf

//³ Carrega filiais da empresa corrente                          ³
DBSelectArea("SM0")
DBSeek(CEMPANT)
While ! Eof() .And. SM0->M0_CODIGO == cEmpAnt
	// Adiciona filial
	aAdd(aFilsCalc,{AllTrim(SM0->M0_CODFIL),SM0->M0_CGC,SM0->M0_FILIAL})
	DBSkip()
EndDo
	
	lQuery    := .T.
	cAliasSD2 := GetNextAlias()  

	cQuery := "SELECT SD2.R_E_C_N_O_ RECSD2 
	cQuery += " FROM "
	cQuery += RetSqlName("SD2")+" SD2 ,"+RetSqlName("SF4")+" SF4 
	cQuery += "WHERE SD2.D_E_L_E_T_ = ' ' "

    If !Empty(MV_PAR01) // DESTINO
       cQuery += " AND SD2.D2_FILIAL IN "+FormatIn(AllTrim(MV_PAR01),";")+"  "
    EndIf

	cQuery += " AND SF4.F4_FILIAL  = SD2.D2_FILIAL AND SF4.D_E_L_E_T_ = ' '  "
	cQuery += " AND SF4.F4_TRANFIL = '1' AND SF4.F4_CODIGO = SD2.D2_TES  "
	
	cQuery += " AND SD2.D2_EMISSAO BETWEEN '"+ DToS(MV_PAR03) +"' AND '"+ DToS(MV_PAR04) +"'  "

    If !Empty(MV_PAR05)
       cQuery += "   AND SD2.D2_DOC >= '" + (MV_PAR05) + "' "
    EndIf
    If !Empty(MV_PAR06)
       cQuery += "   AND SD2.D2_DOC <= '" + (MV_PAR06) + "' "
    EndIf

    If !Empty(MV_PAR07)
       cQuery += "   AND SD2."+SERIENFID("SD2",3,"D2_SERIE")+" >= '" + (MV_PAR07) + "' "
    EndIf
    If !Empty(MV_PAR08)
       cQuery += "   AND SD2."+SERIENFID("SD2",3,"D2_SERIE")+" <= '" + (MV_PAR08) + "' "
    EndIf

    If !Empty(MV_PAR09)
       cQuery += "   AND SD2.D2_COD >= '" + (MV_PAR09) + "' "
    EndIf
    If !Empty(MV_PAR10)
       cQuery += "   AND SD2.D2_COD <= '" + (MV_PAR10) + "' "
    EndIf

    If !Empty(MV_PAR11)
       cQuery += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SB1")+" B1 WHERE B1.D_E_L_E_T_ = ' ' "
	   cQuery += "                                                         AND B1.B1_FILIAL  = '" + xFilial("SB1") + "'"
       cQuery += "                                                         AND B1_GRUPO IN "+FormatIn(AllTrim(MV_PAR11),";")+" ) "
    EndIf

	cQuery += "ORDER BY " + SQLORDER(SD2->(INDEXKEY()))
	
	DBUSEAREA(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD2,.T.,.T.)
	
	DBSelectArea(cAliasSD2)

    _nTot:=nConta:=0
    COUNT TO _nTot
    _cTot:=AllTrim(Str(_nTot))
    DBGoTop()
    
	While (cAliasSD2)->(!Eof())

       SD2->(DBGoTo((cAliasSD2)->RECSD2))

	    nConta++
	    oproc:cCaption := ("Lendo Dados: "+StrZero(nConta,5) +" de "+ _cTot )
	    ProcessMessages()

			// Checa TES
			
			If lQuery //.Or. (!lQuery .And. SF4->(MsSeek(xFilial("SF4")+(cAliasSD2)->D2_TES)) .And. SF4->F4_TRANFIL == "1")
				
				//aEmp :=FWSM0Util():GetSM0Data("01",SD2->D2_FILIAL,{"M0_CGC","M0_CODFIL","M0_FILIAL"})
				aRetNF:=RCOM22BuscaNF(aFilsCalc,"SD2",lUsaFilTrf)
				
				If Len(aRetNF) > 0
					
					// Checa status de acordo com o parametro
					If MV_PAR12 = "3" .Or. (MV_PAR12 = "2" .And. !Empty(aRetNF[3])) .Or. ;
					                       (MV_PAR12 = "1" .And.  Empty(aRetNf[3]))
						
	                    // Posiciona no produto
	                    SB1->(MsSeek(xFilial("SB1")+SD2->D2_COD))

                        _aItens:={}
						aAdd(_aItens,SD2->D2_FILIAL)
						aAdd(_aItens,FWSM0Util():GetSM0FullName("01",SD2->D2_FILIAL))//AllTrim(aEmp[3,2]))//
						If SD2->D2_TIPO $ "DB"
                           aAdd(_aItens,Posicione("SA2",1,xFilial("SA2")+SD2->(D2_CLIENTE+D2_LOJA),"A2_NREDUZ"))
						Else
						   aAdd(_aItens,Posicione("SA1",1,xFilial("SA1")+SD2->(D2_CLIENTE+D2_LOJA),"A1_NREDUZ"))
						EndIf
						aAdd(_aItens,SD2->D2_DOC)
						aAdd(_aItens,SD2->D2_SERIE)
						aAdd(_aItens,SD2->D2_TES)
						aAdd(_aItens,SD2->D2_CF)
						aAdd(_aItens,SD2->D2_COD)
						aAdd(_aItens,SB1->B1_DESC)
						aAdd(_aItens,SB1->B1_GRUPO)
						aAdd(_aItens,SD2->D2_UM)
						aAdd(_aItens,SD2->D2_QUANT)
						aAdd(_aItens,SD2->D2_TOTAL)
						aAdd(_aItens,SD2->D2_VALIPI)
						aAdd(_aItens,SD2->D2_VALICM)
						aAdd(_aItens,SD2->D2_CUSTO1)
						aAdd(_aItens,SD2->D2_EMISSAO)
						// Imprime informacoes da devolucao
						aAdd(_aItens,aRetNf[1])
						If !Empty(aRetNf[3])
						   aAdd(_aItens,aRetNf[2])
						Else
						   aAdd(_aItens,"O documento ainda nao foi classificado (pre-nota)")
						EndIf
					    aAdd(_aItens,aRetNf[3])
						aAdd(_aItens,aRetNf[4])
						aAdd(_aItens,aRetNf[5])
					    aAdd(_aDados,_aItens)
					EndIf
				EndIf
			EndIf
			(cAliasSD2)->(DBSkip())
		//EndDo
		
	EndDo

// Fecha arquivo da query
If lQuery
	DBSelectArea(cAliasSD2)
	DBCloseArea()
	DBSelectArea("SD2")
EndIf
		
// Restaura filial original
cFilAnt:=cFilBack
FWRestArea(aAreaSM0)

If Len(_aDados) > 0 
	
   oproc:cCaption := ("Acertos finais...")
   _aTit:={}
   _aCabXML:={}
   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   //   (_aCabXML,{Titulo             ,1           ,1         ,.F.       })
   aAdd(_aTit,'Filial Origem')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//01
   aAdd(_aTit,'Nome da Filial')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//02
   aAdd(_aTit,'Nome do Cliente')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//02
   aAdd(_aTit,'Documento')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//03
   aAdd(_aTit,'Serie') 
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//04
   aAdd(_aTit,'TES Origem') 
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//05
   aAdd(_aTit,'CFO Origem') 
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//06
   aAdd(_aTit,'Produto') 
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//07
   aAdd(_aTit,'Descricao do Produto')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//08
   aAdd(_aTit,'Grupo do Produto')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//09
   aAdd(_aTit,'UM')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//10
   aAdd(_aTit,'Quantidade')           ; _nPosQtde:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//11
   aAdd(_aTit,'Valor Total')          ; _nPosVrT:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//12
   aAdd(_aTit,'Valor IPI')          ; _nPosVICM:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//12
   aAdd(_aTit,'Valor ICM')          ; _nPosVipi:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//12
   aAdd(_aTit,'Custo Total')          ; _nPosCuT:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//13
   aAdd(_aTit,'Data de Emissao')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,4         ,.F.})//14
   aAdd(_aTit,'Filial Destino')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//15
   aAdd(_aTit,'Nome da Filial')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//16
   aAdd(_aTit,'Data de Digitacao')
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,4         ,.F.})//17
   aAdd(_aTit,'Valor Total Destino')  ; _nPosDVrT:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//18
   aAdd(_aTit,'Custo Total Destino')  ; _nPosDCuT:=Len(_aTit)
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,2         ,.F.})//19

   _cPictQtide:= "9999"+PesqPict("SD2","D2_QUANT")
   _cPictValor:= "9999"+PesqPict("SD2","D2_TOTAL")

//*************************************************************************************************
   _aColXML:=ACLONE(_aDados)//FORMATO CORRETO PARA GERAR O EXCEL EM INGLES COM PONTO PARA DECIMAIS
//*************************************************************************************************
   For L := 1 TO Len(_aDados)//AJUSTE PARA MOSTRAR NA TELA DO U_ITListBox() CORRETA
       _aDados[L,_nPosQtde]:= TRANSFORM(_aDados[L,_nPosQtde],_cPictQtide)
       _aDados[L,_nPosVrT ]:= TRANSFORM(_aDados[L,_nPosVrT ],_cPictValor)
       _aDados[L,_nPosVICM]:= TRANSFORM(_aDados[L,_nPosVICM ],_cPictValor)
       _aDados[L,_nPosVIPI]:= TRANSFORM(_aDados[L,_nPosVIPI ],_cPictValor)
       _aDados[L,_nPosCuT ]:= TRANSFORM(_aDados[L,_nPosCuT ],_cPictValor)
       _aDados[L,_nPosDVrT]:= TRANSFORM(_aDados[L,_nPosDVrT],_cPictValor)
       _aDados[L,_nPosDCuT]:= TRANSFORM(_aDados[L,_nPosDCuT],_cPictValor)
   Next

    _cTitulo:=cTitle+" - "+DToC(DATE())+" - "+Time()
    _cMsgTop:= NIL
	_aSX1:=RCOM022X()
	//                        , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons , _aCab  , bDblClk , _aColXML , bCondMarca,_bLegenda:EVAL(_bLegenda,_aCols,oLbxAux:nAt),_lHasOk,_bHeadClk,_aSX1)
	U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,        ,         ,     ,        ,           ,_aCabXML,         , _aColXML ,           ,                                            ,       ,         ,_aSX1)
Else				
	U_ITMsg("Não há dados para essa seleção",'Atenção!',"Redefina o Filtro por favor.",3)
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa--------: RCOM22BuscaNF
Autor-----------: Alex Wallauer
Data da Criacao-: 23/02/2024
Descrição-------: Funcao que Busca a NF
Parametros------: aFilsCalc,cAliasSD2,lUsaFilTrf
Retorno---------: aRetNf:={aFilsCalc[nAchoFil,1] ,aFilsCalc[nAchoFil,3],SD1->D1_DTDIGIT,SD1->D1_TOTAL,SD1->D1_CUSTO}
===============================================================================================================================
*/                     
Static Function RCOM22BuscaNF(aFilsCalc,cAliasSD2,lUsaFilTrf)
	Local aRetNf      := {"","","",0,0}
//Local nAchoCGC    := 0
	Local nAchoFil    := 0
	Local aArea       := FWGetArea()
	Local cFilBack    := cFilAnt
//Local cCGCOrig    := ""
//Local cCGCDest    := aEmp[1,2]//SM0->M0_CGC
	Local cCodFilOrig := ""
	Local cCodFilDest := SD2->D2_FILIAL//AllTrim(aEmp[2,2])//SM0->M0_CODFIL
	Local _cProduto 	:= ""
	Local lCont			:= .F.

	// Posiciona no fornecedor
	If (cAliasSD2)->D2_TIPO $ "DB"
		DBSelectArea("SA2")
		DBSetOrder(1)
		If MsSeek(xFilial("SA2")+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA)
			cCodFilOrig := SA2->A2_FILTRF
		EndIf
	Else
		// Posiciona no cliente
		cArqCliFor:="SA1"
		DBSelectArea("SA1")
		DBSetOrder(1)
		If MsSeek(xFilial("SA1")+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA)
			cCodFilOrig := SA1->A1_FILTRF
		EndIf
	EndIf
    
	If !Empty(MV_PAR02) .And. !cCodFilOrig $ AllTrim(MV_PAR02)//FILIAL DE DESTINO
       Return {}
    EndIf
	
	// Checa se cliente / fornecedor esta configurado como filial do sistema
	If !Empty(cCodFilOrig) .And. (nAchoFil := aScan(aFilsCalc,{|x| x[1] == AllTrim(cCodFilOrig)})) > 0 
		// Pesquisa se nota fiscal ja foi registrada no destino
		cFilAnt := aFilsCalc[nAchoFil,1]//FILIAL DE DESTINO
		
		If (cAliasSD2)->D2_FILIAL == "40" .And. (cAliasSD2)->D2_COD == "08000000064    " .And. cFilAnt == "01"
			_cProduto	:= "08000000007    "
		ElseIf (cAliasSD2)->D2_FILIAL == "11" .And. (cAliasSD2)->D2_COD == "08000000034    " .And. cFilAnt == "10"
			_cProduto	:= "08000000004    "
		ElseIf (cAliasSD2)->D2_FILIAL == "93" .And. (cAliasSD2)->D2_COD == "080000000088    " .And. cFilAnt == "01"
			_cProduto	:= "08000000007    "
		Else
			_cProduto	:= (cAliasSD2)->D2_COD
		EndIf

		DBSelectArea("SD1")
		DBSetOrder(2)
		
		If (cAliasSD2)->D2_FILIAL == "40" .And. cFilAnt == "01" .And. SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				//SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		ElseIf (cAliasSD2)->D2_FILIAL == "40" .And. cFilAnt == "01" .And. SD1->(DBSeek(xFilial("SD1")+_cProduto+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				//SD1->(DBSeek(xFilial("SD1")+_cProduto+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		ElseIf (cAliasSD2)->D2_FILIAL == "11" .And. cFilAnt == "10" .And. DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE)
				//SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		ElseIf (cAliasSD2)->D2_FILIAL == "11" .And. cFilAnt == "10" .And. SD1->(DBSeek(xFilial("SD1")+_cProduto+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				//SD1->(DBSeek(xFilial("SD1")+_cProduto+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		ElseIf (cAliasSD2)->D2_FILIAL == "93" .And. cFilAnt == "01" .And. SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				//SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		ElseIf (cAliasSD2)->D2_FILIAL == "93" .And. cFilAnt == "01" .And. SD1->(DBSeek(xFilial("SD1")+_cProduto+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				//SD1->(DBSeek(xFilial("SD1")+_cProduto+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		ElseIf SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
			   //SD1->(DBSeek(xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))
				lCont	:= .T.
		EndIf
		If lCont
		   
		    While !Eof() .And. (xFilial("SD1")+(cAliasSD2)->D2_COD+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE == D1_FILIAL+D1_COD+D1_DOC+D1_SERIE .OR.;
							    xFilial("SD1")+_cProduto          +(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE == D1_FILIAL+D1_COD+D1_DOC+D1_SERIE)
		    
			If SD1->D1_QUANT <> (cAliasSD2)->D2_QUANT
			   SD1->(DBSkip())
			   Loop
			EndIf
			// Checa TES
			If !Empty(SD1->D1_TES)
				If SF4->(MsSeek(xFilial("SF4")+SD1->D1_TES)) .And. SF4->F4_TRANFIL == "1"
					// Itens de nota fiscal de entrada
					If SD1->D1_TIPO $ "DB"
						DBSelectArea("SA1")
						DBSetOrder(1)
						If MsSeek(xFilial("SA1")+SD1->D1_FORNECE+SD1->D1_LOJA) .And. AllTrim(SA1->A1_FILTRF) == AllTrim(cCodFilDest)
							aRetNf:={cFilAnt,aFilsCalc[nAchoFil,3],SD1->D1_DTDIGIT,SD1->D1_TOTAL,SD1->D1_CUSTO}
							Exit
						EndIf
					Else
						DBSelectArea("SA2")
						DBSetOrder(1)
						If MsSeek(xFilial("SA2")+SD1->D1_FORNECE+SD1->D1_LOJA) .And. AllTrim(SA2->A2_FILTRF) == AllTrim(cCodFilDest)
							aRetNf:={aFilsCalc[nAchoFil,1] ,aFilsCalc[nAchoFil,3],SD1->D1_DTDIGIT,SD1->D1_TOTAL,SD1->D1_CUSTO}
							Exit
						EndIf
					EndIf
				EndIf
			Else
				// O documento ainda nao foi classificado (pre-nota), portanto o material pode ser considerado "ainda em transito"
				aRetNf:={cFilAnt,aFilsCalc[nAchoFil,3],'',SD1->D1_TOTAL,SD1->D1_CUSTO}
			EndIf
			DBSelectArea("SD1")
			DBSkip()
		    EndDo
		Else
			SD1->(DBSetOrder(19))//D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA
			//DBGoTop()

			SD1->(DBSeek((cAliasSD2)->D2_FILIAL+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE))

			While !SD1->(Eof()) .And.  (cAliasSD2)->D2_FILIAL+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE == SD1->(D1_FILIAL+D1_NFORI+D1_SERIORI)
				   
				If (cAliasSD2)->D2_FILIAL == SD1->D1_FILIAL  .AND.;
				   (cAliasSD2)->D2_COD    == SD1->D1_COD     .AND.;
				   (cAliasSD2)->D2_DOC    == SD1->D1_NFORI   .AND.;
				   (cAliasSD2)->D2_SERIE  == SD1->D1_SERIORI .AND.;
				   (cAliasSD2)->D2_ITEM   == AllTrim(SD1->D1_ITEMORI)//D1_ITEMORI É 4 CARACTES E O D2_ITEM 2 CARACTERES
				 	
					If SD1->D1_FORMUL == "S"
				 		aRetNF[2] := "NF Devolvida - Formulário Próprio" 
				 		aRetNF[3] := DToC(SD1->D1_DTDIGIT)
				 		aRetNF[5] := SD1->D1_CUSTO
				 	Else
				 		aRetNF[2] := "NF Devolvida" 
				 		aRetNf[3] := DToC(SD1->D1_DTDIGIT)
				 		aRetNF[5] := SD1->D1_CUSTO
				 	EndIf
				EndIf
				
				SD1->(DBSkip())
			EndDo

		EndIf

	EndIf
// Reposiciona area original
cFilAnt:=cFilBack
FWRestArea(aArea)
Return aRetNf 

/*
===============================================================================================================================
Programa--------: ValFilial
Autor-----------: Alex Wallauer
Data da Criacao-: 23/02/2024
Descrição-------: Funcao que mostra a aba de parametros do relatório
Parametros------: _cFilial,_cCampo
Retorno---------: .T. ou .F.
===============================================================================================================================
*/                     
Static Function ValFilial(_cFilial,_cCampo)
	Local nI
	Local xVarAux := AllTrim(_cFilial)
	Local _cFilsAcesso := ""

	For nI := 1 To Len(_aAcesso)
		_cFilsAcesso+=_aAcesso[nI][03]+", "
	Next
	If Empty(xVarAux)
		U_ITMsg("Com a "+_cCampo+" em branco, somente as filiais que o usuario tem acesso serao selecionadas: "+_cFilsAcesso,'Atenção!',,3)
		_cFilial:=StrTran( _cFilsAcesso, ", ", ";")
	Else
		aDadAux := U_ITLinDel( xVarAux , ";" )
		SM0->(DBSetOrder(1))
		For nI := 1 To Len(aDadAux)
			If !SM0->(DBSeek(cEmpAnt + aDadAux[nI]))
				U_ITMsg("Filial "+aDadAux[nI]+" informada não existe.",'Atenção!',"Selecione no minimo uma Filial dessa lista: "+_cFilsAcesso,1)
				Return .F.
			EndIf
			If !aDadAux[nI] $ _cFilsAcesso
				U_ITMsg("Filial "+aDadAux[nI]+" informada o usuário não tem acesso.",'Atenção!',"Selecione no minimo uma Filial dessa lista: "+_cFilsAcesso,1)
				Return .F.
			EndIf
		Next
	EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: RCOM022X
Autor-----------: Alex Wallauer
Data da Criacao-: 23/02/2024
Descrição-------: Funcao que mostra a aba de parametros do relatório
Parametros------: Nenhum
Retorno---------: _aPergunte
===============================================================================================================================
*/                     
Static Function RCOM022X()

	Local nAux     := 1
	Local _aDadosParam := {}
	aAdd(_aDadosParam,{"01", "Filial Origem"      , MV_PAR01 })
	aAdd(_aDadosParam,{"02", "Filial Destino"     , MV_PAR02 })
	aAdd(_aDadosParam,{"03", "Data Emissao de"    , MV_PAR03 })
	aAdd(_aDadosParam,{"04", "Data Emissao ate"   , MV_PAR04 })
	aAdd(_aDadosParam,{"05", "Doc saida de"       , MV_PAR05 })
	aAdd(_aDadosParam,{"06", "Doc saida ate"      , MV_PAR06 })
	aAdd(_aDadosParam,{"07", "Serie Doc saída de" , MV_PAR07 })
	aAdd(_aDadosParam,{"08", "Serie Doc saida ate", MV_PAR08 })
	aAdd(_aDadosParam,{"09", "Produto de"         , MV_PAR09 })
	aAdd(_aDadosParam,{"10", "Produto ate"        , MV_PAR10 })
	aAdd(_aDadosParam,{"11", "Grupo de Produtos"  , MV_PAR11 })
	If MV_PAR12 = "1"
		_cMV_PAR12 :="1-Em transito"
	ElseIf MV_PAR12 = "2"
		_cMV_PAR12 :="2-Ja recebidas"
	Else
		_cMV_PAR12 :="3-Todos"
	EndIf
	aAdd(_aDadosParam,{"12", "Lista NFs"          , _cMV_PAR12 })
	If MV_PAR13 = "1"
		_cMV_PAR13 :="1-Produto"
	ElseIf MV_PAR13 = "2"
		_cMV_PAR13 :="2-Documento / Serie"
	Else
		_cMV_PAR13 :="3-Data de emissao"
	EndIf
	aAdd(_aDadosParam,{"13", "Ordenar por"        , _cMV_PAR13 })

	_aPergunte:={}
	For nAux := 1 To Len(_aDadosParam)
		aAdd(_aPergunte,{"Pergunta " + _aDadosParam[nAux,1] + ':',_aDadosParam[nAux,2],_aDadosParam[nAux,3] })
	Next

Return _aPergunte
