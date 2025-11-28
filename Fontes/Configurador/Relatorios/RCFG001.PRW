/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Sporl  |23/08/2016| Chamado 16793. Relatório criado para mostrar os itens habilitados e desabilitados no menu.
Alex Wallauer |15/12/2017| Chamado 22901. Correção de error.log
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCFG001
Autor-------------: Darcio R Sporl
Data da Criacao---: 30/08/2016
Descrição---------: Relatório dos itens de menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCFG001()

Local oReport	:= nil
Private cPerg	:= ""
Private aOrd	:= {} 
Private aFiles	:= {}
Private aSizes	:= {}
Private _nConta := 0
Private cFile	:= CGETFILE( 'Local' , "Selecione o diretorio dos MENUS",0,"SERVIDOR\SYSTEM\MENUS\",.T.,GETF_RETDIRECTORY,.T.,.T.)
//                cGetFile (cMascara], [ cTitulo]                , [ nMascpadrao], [ cDirinicial], [ lSalvar], [ nOpcoes], [ lArvore], [ lKeepCase] )

oReport := RptDef(cPerg)
oReport:PrintDialog()

If _nConta > 0 
	U_ITMsg("Foram lidos "+AllTrim(Str(_nConta))+" MENU(S).","Concluido",,2)
EndIf

Return

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Darcio R Sporl
Data da Criacao---: 23/08/2016
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RptDef(cNome)

Local oReport	:= Nil
Local oSection1	:= Nil
	
oReport:= TReport():New("RELMENU","Relatório Itens de Menu","RELMENU", {|oReport|  Processa( {|| ReportPrint(oReport) })   },"Emissao da Relacao dos menus do sistema.")
oReport:SetLandscape()
oReport:LPARAMPAGE := .F.

oSection1 := TRSection():New(oReport, "Relação dos Menus", {"TRBARQ"},aOrd , .F., .T.)

TRCell():New(oSection1,"CARQMN"		,"TRBARQ","Arquivo Menu"		,"@!",30)

oSection2 := TRSection():New(oSection1, "Relação dos Menus", {"TRBMEN"},aOrd , .F., .T.)

TRCell():New(oSection2,"CTITMN"		,"TRBMEN","Titulo Menu"			,"@!",25)
TRCell():New(oSection2,"CSTAMN"		,"TRBMEN","Status Menu"			,"@!",15)

TRCell():New(oSection2,"CTITPT"		,"TRBMEN","Título Pasta 1"		,"@!",25)
TRCell():New(oSection2,"CSTAPT"		,"TRBMEN","Status Pasta 1"		,"@!",15)

TRCell():New(oSection2,"CTITSB"		,"TRBMEN","Título Pasta 2"		,"@!",25)
TRCell():New(oSection2,"CSTASB"		,"TRBMEN","Status Pasta 2"		,"@!",15)

TRCell():New(oSection2,"CTITSP"		,"TRBMEN","Título Pasta 3"		,"@!",25)
TRCell():New(oSection2,"CSTASP"		,"TRBMEN","Status Pasta 3"		,"@!",15)

TRCell():New(oSection2,"CTITIT"		,"TRBMEN","Título Item Menu"	,"@!",25)
TRCell():New(oSection2,"CFUNIT"		,"TRBMEN","Função Item Menu"	,"@!",25)
TRCell():New(oSection2,"CSTAIT"		,"TRBMEN","Status Item Menu"	,"@!",15)

Return(oReport)

/*
===============================================================================================================================
Programa----------: RptDef
Autor-------------: Darcio R Sporl
Data da Criacao---: 23/08/2016
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(1):Section(1)
Local nX		:= 0
Local cError	:= ""
Local cWarning	:= ""
Local oXml		:= NIl
Local nHandle	:= 0
Local cLine		:= ""
Local cTexto	:=  '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes" ?>' + Chr(13) + Chr(10)
Local aXMLITEM	:= {}
Local aXMLSUB	:= {}
Local aXMLIT	:= {}
Local aXMLSB	:= {},nW,nM,nA,nY,nJ,nB,nC,nL,nI,nD
Local _cNomeMenu:=""

ADir(cFile + "*.XNU", aFiles, aSizes)

oReport:SetMeter(Len(aFiles))
ProcRegua(Len(aFiles))

_cTot:=" / "+AllTrim(Str(Len(aFiles)))
_nConta:=0
For nX := 1 To Len(aFiles)
	If oReport:Cancel()
		Exit
	EndIf
	
	oReport:IncMeter()
	
	_cNomeMenu:=cFile+aFiles[nX]//Variavel criada para ver no error.log
	IncProc("Lendo Menu: "+_cNomeMenu+" - "+AllTrim(Str(_nConta))+_cTot)

	If !("OLD" $ aFiles[nX])

		If File(cFile + aFiles[nX])
	       
	       _nConta++

			oSection1:Init()

			oSection1:Cell("CARQMN")	:SetValue(cFile + aFiles[nX])
			oSection1:PrintLine()

			nHandle := FT_FUse(cFile + aFiles[nX])
			If nHandle == -1
				U_ITMsg('Erro de abertura do menu: '+cFile + aFiles[nX]+' FERROR '+Str(ferror()),"Atenção",,2)
				Loop
			Else
				cTexto	:=  '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes" ?>' + Chr(13) + Chr(10)
				FT_FGoTop()
				While !FT_FEof()
					cLine	:= ""
					If "Title" $ AllTrim(FT_FReadLn()) + Chr(13) + Chr(10)
						If 'lang="pt"' $ AllTrim(FT_FReadLn()) + Chr(13) + Chr(10)
							cLine	:= AllTrim(FT_FReadLn()) + Chr(13) + Chr(10)
						EndIf
					ElseIf !("Words" $ AllTrim(FT_FReadLn()) + Chr(13) + Chr(10))
						cLine	:= AllTrim(FT_FReadLn()) + Chr(13) + Chr(10)
					EndIf
					cTexto	+= cLine
					FT_FSkip()
				End
				FT_FUse() // Fecha arquivo

				cTexto	:= StrTran(cTexto,"&",";")
				cTexto	:= StrTran(cTexto,"</IdemID>","</ItemID>")
				oXml	:= XmlParser( cTexto, "_", @cError, @cWarning )

				If (oXml == NIL )
					oSection2:Cell("CTITMN"):SetValue("Falha ao gerar Objeto XML do menu "+AllTrim(cFile+aFiles[nX])+" : "+AllTrim(cError)+" / "+AllTrim(cWarning))
					Loop
				Else
					oSection2:init()

                    If ValType( XmlChildEx( oXml:_APMENU , "_MENU"	) ) = 'U'
				       oSection2:Cell("CTITMN"):SetValue("Menu: "+AllTrim(cFile+aFiles[nX])+" sem o _MENU "+Str(nL))//U_ITMsg("Menu: "+AllTrim(cFile+aFiles[nX])+" sem o _MENU "+Str(nL),"Atenção",,3)
                       Loop
                    ElseIf ValType( XmlChildEx( oXml:_APMENU , "_MENU"	) ) = 'O'
					   XmlNode2Arr( oXml:_APMENU:_MENU, "_MENU" )
                    EndIf
                    _nTotMenus:=Len(oXml:_APMENU:_MENU)-1//Tira sempre o ultimo menu que é desabilitado
					For nL := 1 To _nTotMenus

                        _aMenu:={}
                        _lMenuItem:=.F.
                        If ValType( XmlChildEx( oXml:_APMENU:_MENU[nL],"_MENU") ) = 'U'
                           If ValType( XmlChildEx( oXml:_APMENU:_MENU[nL],"_MENUITEM") ) = 'U'
                              Loop
                           ElseIf ValType( XmlChildEx( oXml:_APMENU:_MENU[nL],"_MENUITEM") ) = 'O'
 						      _aMenu:={oXml:_APMENU:_MENU[nL]:_MENUITEM}
                           ElseIf ValType( XmlChildEx( oXml:_APMENU:_MENU[nL],"_MENUITEM") ) = 'A'
 						      _aMenu:=oXml:_APMENU:_MENU[nL]:_MENUITEM
                           Else
                              Loop
                           EndIf
                           _lMenuItem:=.T.
                        ElseIf ValType(oXml:_APMENU:_MENU[nL]:_MENU) = "O"
							_aMenu:={oXml:_APMENU:_MENU[nL]:_MENU}
						ElseIf ValType(oXml:_APMENU:_MENU[nL]:_MENU) = "A"
						    _aMenu:=oXml:_APMENU:_MENU[nL]:_MENU
						Else
						    Loop 
						EndIf

						For nI := 1 To Len(_aMenu)
///***************  MENUITEM NIVEL 1 *********************
                           If ValType( XmlChildEx(_aMenu[nI],"_MENUITEM") ) = 'U'
                              aXMLITEM:={}
                           ElseIf ValType( XmlChildEx( _aMenu[nI],"_MENUITEM") ) = 'O'
 						      aXMLITEM:={_aMenu[nI]:_MENUITEM}
                           ElseIf ValType( XmlChildEx( _aMenu[nI],"_MENUITEM") ) = 'A'
 						      aXMLITEM:=_aMenu[nI]:_MENUITEM
                           Else
                              aXMLITEM:={}
                           EndIf
///***************  MENUITEM NIVEL 1 *********************

						   If ValType(aXMLITEM) == "A"
								For nY := 1 To Len(aXMLITEM)

//***************  MENUITEM NIVEL 2 *********************
                                    If ValType( XmlChildEx(aXMLITEM[nY],"_MENUITEM") ) = 'U'
                                       aXMLIT:=aXMLITEM[nY]
                                    ElseIf ValType( XmlChildEx( aXMLITEM[nY],"_MENUITEM") ) = 'O'
 						               aXMLIT:=aXMLITEM[nY]:_MENUITEM
                                    ElseIf ValType( XmlChildEx( aXMLITEM[nY],"_MENUITEM") ) = 'A'
 						               aXMLIT:=aXMLITEM[nY]:_MENUITEM
                                    EndIf
//***************  MENUITEM NIVEL 2 *********************

									If ValType(aXMLIT) = "A"
										For nW := 1 To Len(aXMLIT)
											oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
											oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
											oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
											oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
											oSection2:Cell("CTITSB")	:SetValue(aXMLITEM[nY]:_TITLE:TEXT)
											oSection2:Cell("CSTASB")	:SetValue(aXMLITEM[nY]:_STATUS:TEXT)
											oSection2:Cell("CTITSP")	:SetValue("")
											oSection2:Cell("CSTASP")	:SetValue("")
											oSection2:Cell("CTITIT")	:SetValue(aXMLIT[nW]:_TITLE:TEXT)
											oSection2:Cell("CFUNIT")	:SetValue(aXMLIT[nW]:_FUNCTION:TEXT)
											oSection2:Cell("CSTAIT")	:SetValue(aXMLIT[nW]:_STATUS:TEXT)
											oSection2:PrintLine()
										Next nW

									ElseIf ValType(aXMLIT) == "O"

				                        If ValType( XmlChildEx( oXml:_APMENU:_MENU[nL], "_TITLE"	) ) <> 'U'
										   oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
									    Else
										   oSection2:Cell("CTITMN")	:SetValue("  ")
									    EndIf
				                        If ValType( XmlChildEx( oXml:_APMENU:_MENU[nL], "_STATUS"	) ) <> 'U'
										   oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
									    Else
										   oSection2:Cell("CSTAMN")	:SetValue("   ")
									    EndIf
										oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
										oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
										oSection2:Cell("CTITSB")	:SetValue("")
										oSection2:Cell("CSTASB")	:SetValue("")
										oSection2:Cell("CTITSP")	:SetValue("")
										oSection2:Cell("CSTASP")	:SetValue("")
										oSection2:Cell("CTITIT")	:SetValue(aXMLITEM[nY]:_TITLE:TEXT)
				                        If ValType( XmlChildEx( aXMLITEM[nY] , "_FUNCTION"	) ) <> 'U'
										   oSection2:Cell("CFUNIT")	:SetValue(aXMLITEM[nY]:_FUNCTION:TEXT)
										Else
										   oSection2:Cell("CFUNIT")	:SetValue("   ")
				                        EndIf
										oSection2:Cell("CSTAIT")	:SetValue(aXMLITEM[nY]:_STATUS:TEXT)
										oSection2:PrintLine()

									EndIf

//***************  MENU NIVEL 2 *********************
                                    If ValType( XmlChildEx(aXMLITEM[nY],"_MENU") ) = 'U'
                                       Loop//aXMLTT:=aXMLITEM[nY] // já imprimiu em cima
                                    ElseIf ValType( XmlChildEx( aXMLITEM[nY],"_MENU") ) = 'O'
 						               aXMLTT:={aXMLITEM[nY]:_MENU}
                                    ElseIf ValType( XmlChildEx( aXMLITEM[nY],"_MENU") ) = 'A'
 						               aXMLTT:=aXMLITEM[nY]:_MENU
                                    Else
                                       Loop
                                    EndIf
//***************  MENU NIVEL 2 *********************

									If ValType(aXMLTT) == "O"
										aData := ClassDataArr(aXMLTT)
										If aScan(aData, {|x| AllTrim(x[1]) == "_MENUITEM"}) > 0	
				                           If ValType( XmlChildEx( aXMLTT , "_MENUITEM"	) ) = 'A'
				                              _nTot:=Len(aXMLTT:_MENUITEM)
				                           Else
                                              _nTot:=Len(aXMLTT)
				                           EndIf	

											For nM := 1 To _nTot
												oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
												oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
												oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
												oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
												oSection2:Cell("CTITSB")	:SetValue(aXMLITEM[nY]:_TITLE:TEXT)
												oSection2:Cell("CSTASB")	:SetValue(aXMLITEM[nY]:_STATUS:TEXT)
												oSection2:Cell("CTITSP")	:SetValue(aXMLTT:_TITLE:TEXT)
												oSection2:Cell("CSTASP")	:SetValue(aXMLTT:_STATUS:TEXT)
				                                If ValType( XmlChildEx( aXMLTT[nM] , "_MENUITEM"	) ) = 'A'
												   oSection2:Cell("CTITIT")	:SetValue(aXMLTT:_MENUITEM[nM]:_TITLE:TEXT)
												   oSection2:Cell("CFUNIT")	:SetValue(aXMLTT:_MENUITEM[nM]:_FUNCTION:TEXT)
												   oSection2:Cell("CSTAIT")	:SetValue(aXMLTT:_MENUITEM[nM]:_STATUS:TEXT)
												Else
												   oSection2:Cell("CTITIT")	:SetValue(aXMLTT[nM]:_TITLE:TEXT)
												   oSection2:Cell("CFUNIT")	:SetValue(aXMLTT[nM]:_FUNCTION:TEXT)
												   oSection2:Cell("CSTAIT")	:SetValue(aXMLTT[nM]:_STATUS:TEXT)
												EndIf
												oSection2:PrintLine()
											Next nM
										EndIf
									ElseIf ValType(aXMLTT) == "A"
										For nM := 1 To Len(aXMLTT)

				                           If ValType( XmlChildEx( aXMLTT[nM] , "_MENUITEM"	) ) = 'A'
				                              _nTot:=Len(aXMLTT[nM]:_MENUITEM)
				                           Else
                                              _nTot:=Len(aXMLTT)
				                           EndIf	
											For nA := 1 To _nTot
												oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
												oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
												oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
												oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
												oSection2:Cell("CTITSB")	:SetValue(aXMLITEM[nY]:_TITLE:TEXT)
												oSection2:Cell("CSTASB")	:SetValue(aXMLITEM[nY]:_STATUS:TEXT)
												oSection2:Cell("CTITSP")	:SetValue(aXMLTT[nM]:_TITLE:TEXT)
												oSection2:Cell("CSTASP")	:SetValue(aXMLTT[nM]:_STATUS:TEXT)
												
				                                If ValType( XmlChildEx( aXMLTT[nM] , "_MENUITEM"	) ) = 'A'
												   oSection2:Cell("CTITIT")	:SetValue(aXMLTT[nM]:_MENUITEM[nA]:_TITLE:TEXT)
												   oSection2:Cell("CFUNIT")	:SetValue(aXMLTT[nM]:_MENUITEM[nA]:_FUNCTION:TEXT)
												   oSection2:Cell("CSTAIT")	:SetValue(aXMLTT[nM]:_MENUITEM[nA]:_STATUS:TEXT)
												Else
												   oSection2:Cell("CTITIT")	:SetValue(aXMLTT[nM]:_TITLE:TEXT)
												   oSection2:Cell("CFUNIT")	:SetValue(aXMLTT[nM]:_FUNCTION:TEXT)
												   oSection2:Cell("CSTAIT")	:SetValue(aXMLTT[nM]:_STATUS:TEXT)
												EndIf
												
												oSection2:PrintLine()
											Next nA
										Next nM
									EndIf
								Next nY
							EndIf

///***************  MENU NIVEL 1 *********************
                            If ValType( XmlChildEx(_aMenu[nI],"_MENU") ) = 'U'
                               aXMLSUB:={}
                            ElseIf ValType( XmlChildEx( _aMenu[nI],"_MENU") ) = 'O'
 						       aXMLSUB:={_aMenu[nI]:_MENU}
                            ElseIf ValType( XmlChildEx( _aMenu[nI],"_MENU") ) = 'A'
 						       aXMLSUB:=_aMenu[nI]:_MENU
                            Else
                               aXMLSUB:={}
                            EndIf
///***************  MENU NIVEL 1 *********************

							If ValType(aXMLSUB) == "A"
								For nD := 1 To Len(aXMLSUB)
//***************  MENUITEM NIVEL 3 *********************
                                    If ValType( XmlChildEx(aXMLSUB[nD],"_MENUITEM") ) = 'U'
 						               aXMLSB:=aXMLSUB[nD]
                                    ElseIf ValType( XmlChildEx( aXMLSUB[nD],"_MENUITEM") ) = 'O'
 						               aXMLSB:={aXMLSUB[nD]:_MENUITEM}
                                    ElseIf ValType( XmlChildEx( aXMLSUB[nD],"_MENUITEM") ) = 'A'
 						               aXMLSB:=aXMLSUB[nD]:_MENUITEM
                                    Else
                                       Loop
                                    EndIf
//***************  MENUITEM NIVEL 3 *********************
                                    
									If ValType(aXMLSB) = "A"
										For nJ := 1 To Len(aXMLSB)
											oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
											oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
											oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
											oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
											oSection2:Cell("CTITSB")	:SetValue(aXMLSUB[nD]:_TITLE:TEXT)
											oSection2:Cell("CSTASB")	:SetValue(aXMLSUB[nD]:_STATUS:TEXT)
											oSection2:Cell("CTITSP")	:SetValue("")
											oSection2:Cell("CSTASP")	:SetValue("")
											oSection2:Cell("CTITIT")	:SetValue(aXMLSB[nJ]:_TITLE:TEXT)
											oSection2:Cell("CFUNIT")	:SetValue(aXMLSB[nJ]:_FUNCTION:TEXT)
											oSection2:Cell("CSTAIT")	:SetValue(aXMLSB[nJ]:_STATUS:TEXT)
											oSection2:PrintLine()

										Next nJ
									ElseIf ValType(aXMLSB) == "O"
										oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
										oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
										oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
										oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
										oSection2:Cell("CTITSB")	:SetValue("")
										oSection2:Cell("CSTASB")	:SetValue("")
										oSection2:Cell("CTITSP")	:SetValue("")
										oSection2:Cell("CSTASP")	:SetValue("")
										oSection2:Cell("CTITIT")	:SetValue(aXMLSB:_TITLE:TEXT)
				                        If ValType( XmlChildEx( aXMLSB , "_FUNCTION"	) ) <> 'U'
										   oSection2:Cell("CFUNIT")	:SetValue(aXMLSB:_FUNCTION:TEXT)
										Else
										   oSection2:Cell("CFUNIT")	:SetValue("       ")
				                        EndIf
										oSection2:Cell("CSTAIT")	:SetValue(aXMLSB:_STATUS:TEXT)
										oSection2:PrintLine()
									EndIf

//***************  MENU NIVEL 3 *********************
                                    If ValType( XmlChildEx(aXMLSUB[nD],"_MENU") ) = 'U'
 						               Loop//aXMLRT:=aXMLSUB[nD] já imprimiu em cima
                                    ElseIf ValType( XmlChildEx( aXMLSUB[nD],"_MENU") ) = 'O'
 						               aXMLRT:=aXMLSUB[nD]:_MENU
                                    ElseIf ValType( XmlChildEx( aXMLSUB[nD],"_MENU") ) = 'A'
 						               aXMLRT:=aXMLSUB[nD]:_MENU
                                    Else
                                       Loop
                                    EndIf
//***************  MENU NIVEL 3 *********************

									If ValType(aXMLRT) == "O"
										aData := ClassDataArr(aXMLRT)
										If aScan(aData, {|x| AllTrim(x[1]) == "_MENUITEM"}) > 0
											For nB := 1 To Len(aXMLRT:_MENUITEM)
												oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
												oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
												oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
												oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
												oSection2:Cell("CTITSB")	:SetValue(aXMLSUB[nD]:_TITLE:TEXT)
												oSection2:Cell("CSTASB")	:SetValue(aXMLSUB[nD]:_STATUS:TEXT)
												oSection2:Cell("CTITSP")	:SetValue(aXMLRT:_TITLE:TEXT)
												oSection2:Cell("CSTASP")	:SetValue(aXMLRT:_STATUS:TEXT)
												oSection2:Cell("CTITIT")	:SetValue(aXMLRT:_MENUITEM[nB]:_TITLE:TEXT)
												oSection2:Cell("CFUNIT")	:SetValue(aXMLRT:_MENUITEM[nB]:_FUNCTION:TEXT)
												oSection2:Cell("CSTAIT")	:SetValue(aXMLRT:_MENUITEM[nB]:_STATUS:TEXT)
												oSection2:PrintLine()
											Next nB
										EndIf
									ElseIf ValType(aXMLRT) == "A"
										For nB := 1 To Len(aXMLRT)
                                            If ValType( XmlChildEx(aXMLRT[nB],"_MENUITEM") ) = 'U'
 						                       aXMLSB4:={aXMLRT[nB]}
                                            ElseIf ValType( XmlChildEx( aXMLRT[nB],"_MENUITEM") ) = 'O'
 						                       aXMLSB4:={aXMLRT[nB]:_MENUITEM}
                                            ElseIf ValType( XmlChildEx( aXMLSUB[nD],"_MENUITEM") ) = 'A'
 						                       aXMLSB4:=aXMLRT[nB]:_MENUITEM
                                            Else
                                               Loop
                                            EndIf
											For nC := 1 To Len(aXMLSB4)
												oSection2:Cell("CTITMN")	:SetValue(StrTran(oXml:_APMENU:_MENU[nL]:_TITLE:TEXT,";",""))
												oSection2:Cell("CSTAMN")	:SetValue(oXml:_APMENU:_MENU[nL]:_STATUS:TEXT)
												oSection2:Cell("CTITPT")	:SetValue(_aMenu[nI]:_TITLE:TEXT)
												oSection2:Cell("CSTAPT")	:SetValue(_aMenu[nI]:_STATUS:TEXT)
												oSection2:Cell("CTITSB")	:SetValue(aXMLSUB[nD]:_TITLE:TEXT)
												oSection2:Cell("CSTASB")	:SetValue(aXMLSUB[nD]:_STATUS:TEXT)
												oSection2:Cell("CTITSP")	:SetValue(aXMLRT[nB]:_TITLE:TEXT)
												oSection2:Cell("CSTASP")	:SetValue(aXMLRT[nB]:_STATUS:TEXT)
												oSection2:Cell("CTITIT")	:SetValue(aXMLSB4[nC]:_TITLE:TEXT)
												oSection2:Cell("CFUNIT")	:SetValue(aXMLSB4[nC]:_FUNCTION:TEXT)
												oSection2:Cell("CSTAIT")	:SetValue(aXMLSB4[nC]:_STATUS:TEXT)
												oSection2:PrintLine()
											Next nC
										Next nB
									EndIf
								Next nD
							
							EndIf//ValType(aXMLSUB) == "A"
							
						Next nI
					Next nL
					oSection2:Finish()
					oReport:ThinLine()
				EndIf
			EndIf
		EndIf
	EndIf
	oSection1:Finish()
Next nX
		
oSection1:Enable()
oSection2:Enable()

Return
