/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |01/09/2023| Chamado 44904 - Inclusão de totalizador por verba.
Alex Wallauer |05/12/2023| Chamado 45763 - Fernando. Provocar uma quebra de pagina antes de bater o totais gerais.
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: RGPE001
Autor-------------: Igor Melgaço
Data da Criacao---: 28/04/2023
Descrição---------: Relatório Folha de Recisões dos funcionários Chamado 43217
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE001()
	Local oReport := nil
	Local cPerg:= PadR("RGPE001",10)
	Private _cAlias   := "TRBSRA"
	Private _aOrd:= {"Matricula",;               //ORDEM 01 Analitivo e Sintetico   
					"Nome"}     //ORDEM 13 Sintetico   

	//gero a pergunta de modo oculto, ficando disponível no botão ações relacionadas
	Pergunte(cPerg,.F.)
	
	SET DATE FORMAT TO "DD/MM/YYYY"

	oReport := RptDef(cPerg)
	oReport:SetLandScape()
	oReport:PrintDialog()
Return

/*
===============================================================================================================================
Programa----------: RGPE001
Autor-------------: Igor Melgaço
Data da Criacao---: 28/04/2023
Descrição---------: Definições do relatorio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RptDef(cNome)
	Local oReport   := Nil
	Local oSection1 := Nil
	Local oSection2 := Nil
	Local oSection3 := Nil
	Local oSection4 := Nil
	Local oSection5 := Nil
	Local oSection6 := Nil

	/*Sintaxe: TReport():New(cNome,cTitulo,cPerguntas,bBlocoCodigo,cDescricao)*/
	oReport := TReport():New(cNome,"Relatorio de Valores de Rescisoes ",cNome,{|oReport| ReportPrint(oReport)},"Descrição do meu relatório")
	oReport:SetPortrait()    
	oReport:SetTotalInLine(.F.)

	//Monstando a primeira seção
  	oSection1:= TRSection():New(oReport, "Filial", {"SRA"}, _aOrd, .F., .T.) 

	TRCell():New(oSection1,"RA_FILIAL",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_FILIAL	    })
	TRCell():New(oSection1,"M0_FILIAL",_cAlias,"Nome"/*X3Titulo*/,"@!"/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->M0_FILIAL	})

	oSection2:= TRSection():New(oReport, "Funcionario", {"SRA"}, NIL, .F., .T.) 
	TRCell():New(oSection2,"RA_CC"	   ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_CC	    })
	TRCell():New(oSection2,"RA_TNOTRAB",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_TNOTRAB	})
	TRCell():New(oSection2,"RA_MAT"    ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_MAT	})
	TRCell():New(oSection2,"RA_NOME"   ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_NOME	})
	TRCell():New(oSection2,"RA_DEPIR"  ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_DEPIR	})
	TRCell():New(oSection2,"RA_DEPSF"  ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_DEPSF	})

	oSection3:= TRSection():New(oReport, "Funcionario", {"SRG"}, NIL, .F., .T.) 
	TRCell():New(oSection3,"RA_ADMISSA",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_ADMISSA	})

	TRCell():New(oSection3,"RG_DATADEM",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DATADEM	})
	TRCell():New(oSection3,"RG_DATAHOM",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DATAHOM	})
	TRCell():New(oSection3,"RG_DTAVISO",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DTAVISO	})
	TRCell():New(oSection3,"RG_DTGERAR",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DTGERAR	})
	TRCell():New(oSection3,"RG_DAVISO" ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DAVISO	})
	TRCell():New(oSection3,"RG_TIPORES",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_TIPORES	})
	TRCell():New(oSection3,"RG_DESCTPR",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DESCTPR	})
	TRCell():New(oSection3,"RG_MEDATU" ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_MEDATU	})
	TRCell():New(oSection3,"RG_DFERVEN",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DFERVEN	})
	TRCell():New(oSection3,"RG_DFERPRO",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DFERPRO	})
	TRCell():New(oSection3,"RG_SALMES" ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_SALMES	})
	TRCell():New(oSection3,"RG_SALDIA" ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_SALDIA	})
	TRCell():New(oSection3,"RG_SALHORA",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_SALHORA	})
	TRCell():New(oSection3,"RG_EFETIVA",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_EFETIVA	})

	oSection4:= TRSection():New(oReport, "Tipo Cod.", {"SRV"}, NIL, .F., .T.) 
	TRCell():New(oSection4,"NOME1",_cAlias," "/*X3Titulo*/,"@!"/*Picture*/,67/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RV_TIPOCOD	    })
	TRCell():New(oSection4,"NOME2",_cAlias," "/*X3Titulo*/,"@!"/*Picture*/,68/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RV_TIPOCOD	    })
	TRCell():New(oSection4,"NOME3",_cAlias," "/*X3Titulo*/,"@!"/*Picture*/,67/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RV_TIPOCOD	    })

	oSection5:= TRSection():New(oReport, "Funcionario", {"SRR","SRV"}, NIL, .F., .T.)
	TRCell():New(oSection5,"RRR_PD"	 ,_cAlias,"Verba"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	})
	TRCell():New(oSection5,"RRV_DESC" ,_cAlias,"Descricao"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection5,"RRR_HORAS",_cAlias,"Hrs/Dias"/*X3Titulo*/,/*Picture*/,5/*Tamanho*/,/*lPixel*/,{|| Space(5)	})
	TRCell():New(oSection5,"RRR_VALOR",_cAlias,"Valor"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})
	
	TRCell():New(oSection5,"ESPACO1"  ,_cAlias,"  |"/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| Space(10)	})
	
	TRCell():New(oSection5,"DRR_PD"	 ,_cAlias,"Verba"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	    })
	TRCell():New(oSection5,"DRV_DESC" ,_cAlias,"Descricao"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection5,"DRR_HORAS",_cAlias,"Hrs/Dias"/*X3Titulo*/,/*Picture*/,5/*Tamanho*/,/*lPixel*/,{|| Space(5)	    })
	TRCell():New(oSection5,"DRR_VALOR",_cAlias,"Valor"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})
	
	TRCell():New(oSection5,"ESPACO2",_cAlias,"  |"/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| Space(10)	})

	TRCell():New(oSection5,"BRR_PD"	  ,_cAlias,"Verba"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	    })
	TRCell():New(oSection5,"BRV_DESC" ,_cAlias,"Descricao"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection5,"BRR_HORAS",_cAlias,"Hrs/Dias"/*X3Titulo*/,/*Picture*/,5/*Tamanho*/,/*lPixel*/,{|| Space(5)  	})
	TRCell():New(oSection5,"BRR_VALOR",_cAlias,"Valor"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})

	//Monstando a primeira seção
  	oSection6:= TRSection():New(oReport, "Filial", {"SRA"}, _aOrd, .F., .T.) 

	TRCell():New(oSection6,"RA_FILIAL",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_FILIAL	    })
	TRCell():New(oSection6,"RA_MAT"    ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_MAT	})
	TRCell():New(oSection6,"RA_NOME"   ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_NOME	})
	TRCell():New(oSection6,"RA_CC"	   ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_CC	    })
	TRCell():New(oSection6,"RA_ADMISSA",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RA_ADMISSA	})

	TRCell():New(oSection6,"RG_DATADEM",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DATADEM	})
	TRCell():New(oSection6,"RG_DATAHOM",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DATAHOM	})
	TRCell():New(oSection6,"RG_DTAVISO",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DTAVISO	})
	TRCell():New(oSection6,"RG_TIPORES",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_TIPORES	})
	TRCell():New(oSection6,"RG_DESCTPR",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_DESCTPR	})
	TRCell():New(oSection6,"RG_SALMES" ,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->RG_SALMES	})

	TRCell():New(oSection6,"RRR_1PD"   ,_cAlias,"Verba 1"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	})
	TRCell():New(oSection6,"RRV_1DESC" ,_cAlias,"Descricao 1"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection6,"RRR_1VALOR",_cAlias,"Valor 1"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})
	
	TRCell():New(oSection6,"RRR_2PD"   ,_cAlias,"Verba 2"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	})
	TRCell():New(oSection6,"RRV_2DESC" ,_cAlias,"Descricao 2"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection6,"RRR_2VALOR",_cAlias,"Valor 2"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})

	TRCell():New(oSection6,"RRR_3PD"   ,_cAlias,"Verba 3"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	})
	TRCell():New(oSection6,"RRV_3DESC" ,_cAlias,"Descricao 3"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection6,"RRR_3VALOR",_cAlias,"Valor 3"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})

	TRCell():New(oSection6,"RRR_4PD"   ,_cAlias,"Verba 4"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	})
	TRCell():New(oSection6,"RRV_4DESC" ,_cAlias,"Descricao 4"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection6,"RRR_4VALOR",_cAlias,"Valor 4"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})

	TRCell():New(oSection6,"RRR_5PD"   ,_cAlias,"Verba 5"/*X3Titulo*/,/*Picture*/,4/*Tamanho*/,/*lPixel*/,{|| Space(4)	})
	TRCell():New(oSection6,"RRV_5DESC" ,_cAlias,"Descricao 5"/*X3Titulo*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,{|| Space(30)	})
	TRCell():New(oSection6,"RRR_5VALOR",_cAlias,"Valor 5"/*X3Titulo*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,{|| Space(20)	})

	oReport:SetTotalInLine(.F.)
       
    //Aqui, farei uma quebra  por seção
	oSection1:SetPageBreak(.T.)
	oSection1:SetTotalText(" ")				

Return(oReport)

/*
===============================================================================================================================
Programa----------: RGPE001
Autor-------------: Igor Melgaço
Data da Criacao---: 28/04/2023
Descrição---------: Impressao do relatorio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)	 
	Local oSection3 := oReport:Section(3)	 
	Local oSection4 := oReport:Section(4)	 
	Local oSection5 := oReport:Section(5)	 
	Local oSection6 := oReport:Section(6)	
	Local cQuery    := ""
	Local cFiltro   := ""
	Local nOrdem   	:= oReport:Section(1):GetOrder()
	Local i := 0
	Local _cFilial := ""
	Local _cMatric := ""
	Local _cTipo   := ""
	Local aSectionR := {}
	Local aSectionD := {}
	Local aSectionB := {}
	Local aTSectionR := {}
	Local aTSectionD := {}
	Local aTSectionB := {}
	Local nTotalDesp := 0
	Local nTotalRec := 0
	Local nTotalHDesp := 0
	Local nTotalHRec := 0
	Local nTotalFil := 0
	Local nPos := 0
	
	Local _cRA_FILIAL  := ""
	Local _cRA_CC      := ""
	Local _cRA_MAT     := ""
	Local _cRA_NOME    := "" 
	Local _cRA_ADMISSA := ""
	Local _cRG_DATAHOM := ""
	Local _cRG_DATADEM := ""
	Local _cRG_DTAVISO := ""
	Local _cRG_TIPORES := ""
	Local _cRG_DRES    := ""
	Local _cRG_SALMES  := ""

	Local _c1RR_PD := ""
	Local _c1RV_DESC := ""
	Local _c1RR_HORAS := ""
	Local _c1RR_VALOR := ""

	Local _c2RR_PD := ""
	Local _c2RV_DESC := ""
	Local _c2RR_HORAS := ""
	Local _c2RR_VALOR := ""

	Local _c3RR_PD := ""
	Local _c3RV_DESC := ""
	Local _c3RR_HORAS := ""
	Local _c3RR_VALOR := ""

	Local _c4RR_PD := ""
	Local _c4RV_DESC := ""
	Local _c4RR_HORAS := ""
	Local _c4RR_VALOR := ""

	Local _c5RR_PD := ""
	Local _c5RV_DESC := ""
	Local _c5RR_HORAS := ""
	Local _c5RR_VALOR := ""

	SET DATE FORMAT TO "DD/MM/YYYY"
	
	//Filtros da Query
	If !Empty(AllTrim(MV_PAR01))
		cFiltro += "		AND RA_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";")
	EndIf

	If !Empty(AllTrim(MV_PAR02))
		cFiltro += "		AND RA_CC IN " + FormatIn(AllTrim(MV_PAR02),";")
	EndIf
	
	If !Empty(AllTrim(MV_PAR03))
		cFiltro += "		AND RA_TNOTRAB IN " + FormatIn(AllTrim(MV_PAR03),";")
	EndIf

	If !Empty(AllTrim(MV_PAR04))
		cFiltro += "		AND RA_MAT  IN " + FormatIn(AllTrim(MV_PAR04),";")
	EndIf

	If !Empty(AllTrim(MV_PAR05))
		cFiltro += "		AND RA_NOME  IN " + FormatIn(AllTrim(MV_PAR05),";")
	EndIf

	If !Empty(AllTrim(MV_PAR06)) .And. AllTrim(MV_PAR06) <> "*****"
		cFiltro += "		AND SRA.RA_SITFOLH IN " + FormatIn(AllTrim(StrTran(MV_PAR06,"*","")),";")
	EndIf

	If !Empty(AllTrim(MV_PAR07)) .And. AllTrim(MV_PAR07) <> "***************"
		cFiltro += "		AND SRA.RA_CATFUNC IN " + FormatIn(AllTrim(StrTran(MV_PAR07,"*","")),";") 
	EndIf 

	If !Empty(AllTrim(MV_PAR08))
		cFiltro += "  		AND	SRG.RG_EFETIVA IN " + FormatIn(AllTrim(MV_PAR08),";")
	EndIf

	If !Empty(AllTrim(DToS(MV_PAR09)))
		cFiltro += "		AND (RG_DATADEM BETWEEN '"+DToS(MV_PAR09)+"' AND '"+DToS(MV_PAR10)+"')" //Data de Demissao
	EndIf

	If !Empty(AllTrim(DToS(MV_PAR11)))
		cFiltro += "		AND (RG_DATAHOM BETWEEN '"+DToS(MV_PAR11)+"' AND '"+DToS(MV_PAR12)+"')" //Data Homologacao
	EndIf
	
	If !Empty(AllTrim(DToS(MV_PAR13)))
		cFiltro += "		AND (RG_DTGERAR BETWEEN '"+DToS(MV_PAR13)+"' AND '"+DToS(MV_PAR14)+"')" //Data geração
	EndIf

	If MV_PAR15 = 1 //Normal
		cFiltro += "		AND SRG.RG_RESCDIS = '0'"
	ElseIf MV_PAR15 = 2 //Complementar
		cFiltro += "		AND SRG.RG_RESCDIS = '1'"	
	ElseIf MV_PAR15 = 3 //Por dissídio
		cFiltro += "		AND SRG.RG_RESCDIS = '2'"	
	EndIf

	If !Empty(AllTrim(MV_PAR17))
		cFiltro += "		AND SRR.RR_PD IN " + FormatIn(AllTrim(MV_PAR17),";")
	EndIf

	//Monto minha consulta conforme parametros passado
	cFilSRV :=  FWJoinFilial("SRV", "SRA") 
	cFilSR6 :=  FWJoinFilial("SR6", "SRA") 
	cFilCTT :=  FWJoinFilial("CTT", "SRA") 

	cFilSRV := StrTran(cFilSRV, "SUBSTRING", "SubStr")
	cFilSR6 := StrTran(cFilSR6, "SUBSTRING", "SubStr")
	cFilCTT := StrTran(cFilCTT, "SUBSTRING", "SubStr")

	cQuery := "	SELECT RA_FILIAL,M0_FILIAL , RA_CC, RA_TNOTRAB,RA_ADMISSA, RA_MAT, RA_NOME, RA_DEPIR, RA_DEPSF, "
	cQuery += "		RG_FILIAL, RG_MAT, RG_DATADEM, RG_DATAHOM, RG_DTAVISO, RG_DTGERAR, RG_DAVISO, RG_TIPORES, RG_MEDATU, "
	cQuery += "		RG_DFERVEN, RG_DFERPRO, RG_SALMES, RG_SALDIA, RG_SALHORA, RG_EFETIVA,"
	cQuery += "		RR_FILIAL, RR_MAT, RR_PD, RR_HORAS, RR_TIPO1, RR_VALOR, RR_TIPO3, RR_DATA,"
	cQuery += "		RV_COD, RV_DESC, RV_TIPOCOD,"
	cQuery += "		R6_DESC, CTT_DESC01"
	cQuery += "	FROM "+ RETSQLNAME("SRA")+" SRA,"+RETSQLNAME("SRG")+" SRG,"+RETSQLNAME("SRR")+" SRR," +RETSQLNAME("SRV")+" SRV,"+RETSQLNAME("SR6")+" SR6,"+RETSQLNAME("CTT")+" CTT , SYS_COMPANY SM0 "
	cQuery += "	WHERE SRA.RA_FILIAL 	= SRG.RG_FILIAL				    "
	cQuery += "	    AND M0_CODFIL       = RA_FILIAL                     "
	cQuery += "		AND	SRA.RA_MAT 		= SRG.RG_MAT					"
	cQuery += "		AND	SRA.RA_FILIAL 	= SRR.RR_FILIAL					"
	cQuery += "		AND	SRA.RA_MAT 		= SRR.RR_MAT					"
	cQuery += "		AND	SRR.RR_TIPO3	= 'R'							"
	cQuery += "     AND SRR.RR_DATA     = SRG.RG_DTGERAR                "
	cQuery += "		AND	"+cFilSRV
	cQuery += "		AND	SRR.RR_PD		= SRV.RV_COD"
	cQuery += "		AND "+cFilSR6
	cQuery += "		AND SR6.R6_TURNO	= SRA.RA_TNOTRAB "
	cQuery += "		AND "+cFilCTT
	cQuery += "		AND CTT.CTT_CUSTO	= SRA.RA_CC							"
	cQuery += "		AND SRA.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SRG.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SRR.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SR6.D_E_L_E_T_ = ' ' "
	cQuery += "		AND SRV.D_E_L_E_T_ = ' ' "
	cQuery += "		AND CTT.D_E_L_E_T_ = ' ' "
	cQuery += cFiltro
	If MV_PAR16 = 2 .And. Empty(AllTrim(MV_PAR17))
		cQuery += "		AND	(SRR.RR_PD = '428' OR SRR.RR_PD = '727')"
	EndIf
	If nOrdem = 1
		cQuery += "		ORDER BY RA_FILIAL, RA_MAT, RV_TIPOCOD, RR_PD "
	Else
		cQuery += "		ORDER BY RA_FILIAL, RA_NOME, RA_MAT, RV_TIPOCOD, RR_PD "
	EndIf

	cQuery := ChangeQuery(cQuery)

	//Se o alias estiver aberto, irei fechar, isso ajuda a evitar erros
	If Select(_cAlias) > 0
		DBSelectArea(_cAlias)
		DBCloseArea()
	EndIf
	
	//crio o novo alias
	TCQUERY cQuery New Alias (_cAlias)

	DBSelectArea(_cAlias)
	(_cAlias)->(DBGoTop())
	
	oReport:SetMeter((_cAlias)->(LastRec()))	

If MV_PAR16 = 1
	//Irei percorrer todos os meus registros
	While !Eof()
		
		If oReport:Cancel()
			Exit
		EndIf
		
		If _cFilial <> (_cAlias)->RA_FILIAL
			nTotalFil := 0
			If !Empty(AllTrim(_cFilial))
				oSection1:Finish()
			EndIf

			//inicializo a primeira seção
			oSection1:Init()

			oReport:IncMeter()
						
			IncProc("Imprimindo... ")
			
			//imprimo a primeira seção				
			oSection1:Cell("RA_FILIAL"):SetValue((_cAlias)->RA_FILIAL)
			//oSection1:Cell("DESCRICAO"):SetValue((_cAlias)->DESCRICAO)				
			oSection1:PrintLine()
		EndIf

		If _cMatric <> (_cAlias)->RA_MAT

			If !Empty(AllTrim(_cMatric))
				oSection2:Finish()
				oSection3:Finish()
				oSection4:Finish()
				oSection5:Finish()
			EndIf

			//inicializo a segunda seção
			oSection2:init()

			oSection2:Cell("RA_CC"):SetValue((_cAlias)->RA_CC)
			oSection2:Cell("RA_TNOTRAB"):SetValue((_cAlias)->RA_TNOTRAB)			
			oSection2:Cell("RA_MAT"):SetValue((_cAlias)->RA_MAT)	
			oSection2:Cell("RA_NOME"):SetValue((_cAlias)->RA_NOME)	
			oSection2:Cell("RA_DEPIR"):SetValue((_cAlias)->RA_DEPIR)	
			oSection2:Cell("RA_DEPSF"):SetValue((_cAlias)->RA_DEPSF)		
			oSection2:PrintLine()

			//inicializo a segunda seção
			oSection3:init()

			oSection3:Cell("RA_ADMISSA"):SetValue(DToC(SToD((_cAlias)->RA_ADMISSA)))
			oSection3:Cell("RG_DATADEM"):SetValue(DToC(SToD((_cAlias)->RG_DATADEM)))
			oSection3:Cell("RG_DATAHOM"):SetValue(DToC(SToD((_cAlias)->RG_DATAHOM)))			
			oSection3:Cell("RG_DTAVISO"):SetValue(DToC(SToD((_cAlias)->RG_DTAVISO)))	
			oSection3:Cell("RG_DTGERAR"):SetValue(DToC(SToD((_cAlias)->RG_DTGERAR)))	
			oSection3:Cell("RG_DAVISO"):SetValue((_cAlias)->RG_DAVISO)	
			oSection3:Cell("RG_TIPORES"):SetValue((_cAlias)->RG_TIPORES)
			oSection3:Cell("RG_DESCTPR"):SetValue(fDescRCC("S043",(_cAlias)->RG_TIPORES,1,2,3,30) )
			oSection3:Cell("RG_MEDATU"):SetValue(If( (_cAlias)->RG_MEDATU == "S", "Sim" , "Não"))
			oSection3:Cell("RG_DFERVEN"):SetValue((_cAlias)->RG_DFERVEN)
			oSection3:Cell("RG_SALMES"):SetValue((_cAlias)->RG_SALMES)
			oSection3:Cell("RG_SALDIA"):SetValue((_cAlias)->RG_SALDIA)
			oSection3:Cell("RG_SALHORA"):SetValue((_cAlias)->RG_SALHORA)
			oSection3:Cell("RG_EFETIVA"):SetValue((_cAlias)->RG_EFETIVA)
			oSection3:PrintLine()

			oSection5:init()
		EndIf

		If (_cAlias)->RV_TIPOCOD = "1"
			aAdd(aSectionR,{(_cAlias)->RR_PD,(_cAlias)->RV_DESC,(_cAlias)->RR_HORAS,(_cAlias)->RR_VALOR})
			//Alimenta o Array totalizador
			If (nPos := aScan(aTSectionR,{|x| x[1] ==(_cAlias)->RR_PD})) = 0
				aAdd(aTSectionR,{(_cAlias)->RR_PD,(_cAlias)->RV_DESC,(_cAlias)->RR_HORAS,(_cAlias)->RR_VALOR})
			Else
				aTSectionR[nPos,3] += (_cAlias)->RR_HORAS
				aTSectionR[nPos,4] += (_cAlias)->RR_VALOR
			EndIf
		ElseIf (_cAlias)->RV_TIPOCOD = "2"
			aAdd(aSectionD,{(_cAlias)->RR_PD,(_cAlias)->RV_DESC,(_cAlias)->RR_HORAS,(_cAlias)->RR_VALOR})
			//Alimenta o Array totalizador
			If (nPos := aScan(aTSectionD,{|x| x[1] ==(_cAlias)->RR_PD})) = 0
				aAdd(aTSectionD,{(_cAlias)->RR_PD,(_cAlias)->RV_DESC,(_cAlias)->RR_HORAS,(_cAlias)->RR_VALOR})
			Else
				aTSectionD[nPos,3] += (_cAlias)->RR_HORAS
				aTSectionD[nPos,4] += (_cAlias)->RR_VALOR
			EndIf
		Else
			aAdd(aSectionB,{(_cAlias)->RR_PD,(_cAlias)->RV_DESC,(_cAlias)->RR_HORAS,(_cAlias)->RR_VALOR})
			//Alimenta o Array totalizador
			If (nPos := aScan(aTSectionB,{|x| x[1] ==(_cAlias)->RR_PD})) = 0
				aAdd(aTSectionB,{(_cAlias)->RR_PD,(_cAlias)->RV_DESC,(_cAlias)->RR_HORAS,(_cAlias)->RR_VALOR})
			Else
				aTSectionB[nPos,3] += (_cAlias)->RR_HORAS
				aTSectionB[nPos,4] += (_cAlias)->RR_VALOR
			EndIf
		EndIf

		_cFilial := (_cAlias)->RA_FILIAL
		_cMatric := (_cAlias)->RA_MAT
		_cTipo   := (_cAlias)->RV_TIPOCOD

		(_cAlias)->(DBSkip())

		If _cMatric <> (_cAlias)->RA_MAT .Or. (_cAlias)->(Eof())

			oSection4:init()
			
			oSection4:Cell("NOME1"):SetValue("RECEITAS")
			oSection4:Cell("NOME2"):SetValue("DESPESAS")
			oSection4:Cell("NOME3"):SetValue("BASES")
			oSection4:PrintLine()

			nTamR := Len(aSectionR)
			nTamD := Len(aSectionD)
			nTamB := Len(aSectionB)

			nTam := nTamR

			If nTam < nTamD
				nTam := nTamD
			EndIf

			If nTam < nTamB
				nTam := nTamB
			EndIf

			nTotalDesp := 0
			nTotalRec := 0
			nTotalHDesp := 0
			nTotalHRec := 0

			For i := 1 To nTam
				If i <= nTamR
					oSection5:Cell("RRR_PD"):SetValue(aSectionR[i][1])
					oSection5:Cell("RRV_DESC"):SetValue(aSectionR[i][2])			
					oSection5:Cell("RRR_HORAS"):SetValue(aSectionR[i][3])	
					oSection5:Cell("RRR_VALOR"):SetValue(Transform(aSectionR[i][4],"@E 999,999,999.99"))	
					nTotalRec += aSectionR[i][4]
					nTotalHRec += aSectionR[i][3]
				Else
					oSection5:Cell("RRR_PD"):SetValue("")
					oSection5:Cell("RRV_DESC"):SetValue("")		
					oSection5:Cell("RRR_HORAS"):SetValue("")	
					oSection5:Cell("RRR_VALOR"):SetValue("")	
				EndIf
				If i <= nTamD  
					oSection5:Cell("DRR_PD"):SetValue(aSectionD[i][1])
					oSection5:Cell("DRV_DESC"):SetValue(aSectionD[i][2])			
					oSection5:Cell("DRR_HORAS"):SetValue(aSectionD[i][3])	
					oSection5:Cell("DRR_VALOR"):SetValue(Transform(aSectionD[i][4],"@E 999,999,999.99") )		
					nTotalDesp += aSectionD[i][4]
					nTotalHDesp += aSectionD[i][3]
				Else
					oSection5:Cell("DRR_PD"):SetValue("")
					oSection5:Cell("DRV_DESC"):SetValue("")			
					oSection5:Cell("DRR_HORAS"):SetValue("")
					oSection5:Cell("DRR_VALOR"):SetValue("")	
				EndIf

				If i <= nTamB
					oSection5:Cell("BRR_PD"):SetValue(aSectionB[i][1])
					oSection5:Cell("BRV_DESC"):SetValue(aSectionB[i][2])			
					oSection5:Cell("BRR_HORAS"):SetValue(aSectionB[i][3])	
					oSection5:Cell("BRR_VALOR"):SetValue(Transform(aSectionB[i][4],"@E 999,999,999.99"))		
				Else
					oSection5:Cell("BRR_PD"):SetValue("")
					oSection5:Cell("BRV_DESC"):SetValue("")		
					oSection5:Cell("BRR_HORAS"):SetValue("")	
					oSection5:Cell("BRR_VALOR"):SetValue("")				
				EndIf
				oSection5:Cell("ESPACO1"):SetValue("|")	
				oSection5:Cell("ESPACO2"):SetValue("|")	
				oSection5:PrintLine()

			Next
			oReport:ThinLine()

			oSection5:Cell("RRR_PD"):SetValue("")
			oSection5:Cell("RRV_DESC"):SetValue("Totais Recebimentos =>")		
			oSection5:Cell("RRR_HORAS"):SetValue(nTotalHRec)	
			oSection5:Cell("RRR_VALOR"):SetValue(Transform(nTotalRec,"@E 999,999,999.99") )	
		
			oSection5:Cell("DRR_PD"):SetValue("")
			oSection5:Cell("DRV_DESC"):SetValue("Totais Despesas =>")			
			oSection5:Cell("DRR_HORAS"):SetValue(nTotalHDesp)
			oSection5:Cell("DRR_VALOR"):SetValue(Transform(nTotalDesp,"@E 999,999,999.99") )

			oSection5:Cell("BRR_PD"):SetValue("")
			oSection5:Cell("BRV_DESC"):SetValue("Salario Liq")		
			oSection5:Cell("BRR_HORAS"):SetValue("")	
			oSection5:Cell("BRR_VALOR"):SetValue(Transform(nTotalRec - nTotalDesp,"@E 999,999,999.99") )	

			oSection5:PrintLine()
			oReport:ThinLine()

			nTotalFil += (nTotalRec - nTotalDesp)

			aSectionR := {}
			aSectionD := {}
			aSectionB := {}
			
		EndIf

		If _cFilial <> (_cAlias)->RA_FILIAL .Or. (_cAlias)->(Eof())

			oReport:SkipLine(3)
			oReport:ThinLine()

			oSection5:Cell("RRR_PD"):SetValue("")
			oSection5:Cell("RRV_DESC"):SetValue("Total Filial "+_cFilial)		
			oSection5:Cell("RRR_HORAS"):SetValue("")	
			oSection5:Cell("RRR_VALOR"):SetValue("" )	
		
			oSection5:Cell("DRR_PD"):SetValue("")
			oSection5:Cell("DRV_DESC"):SetValue("")			
			oSection5:Cell("DRR_HORAS"):SetValue("")
			oSection5:Cell("DRR_VALOR"):SetValue("" )

			oSection5:Cell("BRR_PD"):SetValue("")
			oSection5:Cell("BRV_DESC"):SetValue("")		
			oSection5:Cell("BRR_HORAS"):SetValue("")	
			oSection5:Cell("BRR_VALOR"):SetValue(Transform(nTotalFil,"@E 999,999,999,999.99") )	

			oSection5:Cell("ESPACO1"):SetValue("")	
			oSection5:Cell("ESPACO2"):SetValue("")	

			oSection5:PrintLine()
		EndIf
	EndDo

	oSection1:Finish()
	oSection2:Finish()
	oSection3:Finish()
	oSection4:Finish()
	oSection5:Finish()
	oReport:ThinLine()

	//************** COMEÇA AQUI A IMPRESSÃO DOS TOTAIS ********************************************
	//oReport:SkipLine(5)
	oReport:EndPage()
	oReport:StartPage()

	oReport:ThinLine()

	oSection4:init()

	oSection4:Cell("NOME1"):SetValue("Totalizador")
	oSection4:Cell("NOME2"):SetValue("")
	oSection4:Cell("NOME3"):SetValue("")
	oSection4:PrintLine()

	oReport:SkipLine(1)

	oSection4:Cell("NOME1"):SetValue("RECEITAS")
	oSection4:Cell("NOME2"):SetValue("DESPESAS")
	oSection4:Cell("NOME3"):SetValue("BASES")
	oSection4:PrintLine()



	oSection5:init()

	nTotalDesp  := 0
	nTotalRec   := 0
	nTotalHDesp := 0
	nTotalHRec  := 0

	nTamR := Len(aTSectionR)
	nTamD := Len(aTSectionD)
	nTamB := Len(aTSectionB)

    aSort(aTSectionR ,,, {|x,y| x[1] < y[1] } )
    aSort(aTSectionD ,,, {|x,y| x[1] < y[1] } )
    aSort(aTSectionB ,,, {|x,y| x[1] < y[1] } )
	
	nTam := nTamR

	If nTam < nTamD
		nTam := nTamD
	EndIf

	If nTam < nTamB
		nTam := nTamB
	EndIf

	For i := 1 To nTam
		If i <= nTamR
			oSection5:Cell("RRR_PD"):SetValue(aTSectionR[i][1])
			oSection5:Cell("RRV_DESC"):SetValue(aTSectionR[i][2])			
			oSection5:Cell("RRR_HORAS"):SetValue(aTSectionR[i][3])	
			oSection5:Cell("RRR_VALOR"):SetValue(Transform(aTSectionR[i][4],"@E 999,999,999.99"))	
			nTotalRec += aTSectionR[i][4]
			nTotalHRec += aTSectionR[i][3]
		Else
			oSection5:Cell("RRR_PD"):SetValue("")
			oSection5:Cell("RRV_DESC"):SetValue("")		
			oSection5:Cell("RRR_HORAS"):SetValue("")	
			oSection5:Cell("RRR_VALOR"):SetValue("")	
		EndIf
		If i <= nTamD  
			oSection5:Cell("DRR_PD"):SetValue(aTSectionD[i][1])
			oSection5:Cell("DRV_DESC"):SetValue(aTSectionD[i][2])			
			oSection5:Cell("DRR_HORAS"):SetValue(aTSectionD[i][3])	
			oSection5:Cell("DRR_VALOR"):SetValue(Transform(aTSectionD[i][4],"@E 999,999,999.99") )		
			nTotalDesp += aTSectionD[i][4]
			nTotalHDesp += aTSectionD[i][3]
		Else
			oSection5:Cell("DRR_PD"):SetValue("")
			oSection5:Cell("DRV_DESC"):SetValue("")			
			oSection5:Cell("DRR_HORAS"):SetValue("")
			oSection5:Cell("DRR_VALOR"):SetValue("")	
		EndIf

		If i <= nTamB
			oSection5:Cell("BRR_PD"):SetValue(aTSectionB[i][1])
			oSection5:Cell("BRV_DESC"):SetValue(aTSectionB[i][2])			
			oSection5:Cell("BRR_HORAS"):SetValue(aTSectionB[i][3])	
			oSection5:Cell("BRR_VALOR"):SetValue(Transform(aTSectionB[i][4],"@E 999,999,999.99"))		
		Else
			oSection5:Cell("BRR_PD"):SetValue("")
			oSection5:Cell("BRV_DESC"):SetValue("")		
			oSection5:Cell("BRR_HORAS"):SetValue("")	
			oSection5:Cell("BRR_VALOR"):SetValue("")				
		EndIf
		oSection5:Cell("ESPACO1"):SetValue("|")	
		oSection5:Cell("ESPACO2"):SetValue("|")	
		oSection5:PrintLine()

	Next

	oReport:ThinLine()

	oSection5:Cell("RRR_PD"):SetValue("")
	oSection5:Cell("RRV_DESC"):SetValue("Totais Recebimentos =>")		
	oSection5:Cell("RRR_HORAS"):SetValue(nTotalHRec)	
	oSection5:Cell("RRR_VALOR"):SetValue(Transform(nTotalRec,"@E 999,999,999.99") )	

	oSection5:Cell("DRR_PD"):SetValue("")
	oSection5:Cell("DRV_DESC"):SetValue("Totais Despesas =>")			
	oSection5:Cell("DRR_HORAS"):SetValue(nTotalHDesp)
	oSection5:Cell("DRR_VALOR"):SetValue(Transform(nTotalDesp,"@E 999,999,999.99") )

	oSection5:Cell("BRR_PD"):SetValue("")
	oSection5:Cell("BRV_DESC"):SetValue("Salario Liq")		
	oSection5:Cell("BRR_HORAS"):SetValue("")	
	oSection5:Cell("BRR_VALOR"):SetValue(Transform(nTotalRec - nTotalDesp,"@E 999,999,999.99") )	

	oSection5:PrintLine()
	oReport:ThinLine()

	oSection4:Finish()
	oSection5:Finish()
	oReport:ThinLine()

Else
	//Irei percorrer todos os meus registros
	While !Eof()
		
		If oReport:Cancel()
			Exit
		EndIf
		//inicializo a primeira seção
		oSection6:Init()

		oReport:IncMeter()
					
		IncProc("Imprimindo... ")	

		_cRA_FILIAL  := (_cAlias)->RA_FILIAL
		_cRA_CC      := (_cAlias)->RA_CC
		_cRA_MAT     := (_cAlias)->RA_MAT
		_cRA_NOME    := (_cAlias)->RA_NOME
		_cRA_ADMISSA := DToC(SToD((_cAlias)->RA_ADMISSA))
		_cRG_DATAHOM := DToC(SToD((_cAlias)->RG_DATAHOM))
		_cRG_DATADEM := DToC(SToD((_cAlias)->RG_DATADEM))
		_cRG_DTAVISO := DToC(SToD((_cAlias)->RG_DTAVISO))
		_cRG_TIPORES := (_cAlias)->RG_TIPORES
		_cRG_DRES    := fDescRCC("S043",(_cAlias)->RG_TIPORES,1,2,3,30)
		_cRG_SALMES  := (_cAlias)->RG_SALMES
		
		If Empty(AllTrim(_c1RR_PD))
			_c1RR_PD := (_cAlias)->RR_PD
			_c1RV_DESC := (_cAlias)->RV_DESC
			_c1RR_VALOR := Transform((_cAlias)->RR_VALOR,"@E 999,999,999.99")
		ElseIf Empty(AllTrim(_c2RR_PD))
			_c2RR_PD := (_cAlias)->RR_PD
			_c2RV_DESC := (_cAlias)->RV_DESC
			_c2RR_VALOR := Transform((_cAlias)->RR_VALOR,"@E 999,999,999.99")
		ElseIf Empty(AllTrim(_c3RR_PD))
			_c3RR_PD := (_cAlias)->RR_PD
			_c3RV_DESC := (_cAlias)->RV_DESC
			_c3RR_VALOR := Transform((_cAlias)->RR_VALOR,"@E 999,999,999.99")
		ElseIf Empty(AllTrim(_c4RR_PD))
			_c4RR_PD := (_cAlias)->RR_PD
			_c4RV_DESC := (_cAlias)->RV_DESC
			_c4RR_VALOR := Transform((_cAlias)->RR_VALOR,"@E 999,999,999.99")
		ElseIf Empty(AllTrim(_c5RR_PD))
			_c5RR_PD := (_cAlias)->RR_PD
			_c5RV_DESC := (_cAlias)->RV_DESC
			_c5RR_VALOR := Transform((_cAlias)->RR_VALOR,"@E 999,999,999.99")
		EndIf
		
		_cMatric := (_cAlias)->RA_MAT

		(_cAlias)->(DBSkip())

		If _cMatric <> (_cAlias)->RA_MAT .Or. (_cAlias)->(Eof())
			//inicializo a segunda seção
			oSection6:init()

			oSection6:Cell("RA_FILIAL"):SetValue(_cRA_FILIAL)	
			oSection6:Cell("RA_CC"):SetValue(_cRA_CC)	
			oSection6:Cell("RA_MAT"):SetValue(_cRA_MAT)	
			oSection6:Cell("RA_NOME"):SetValue(_cRA_NOME)	

			oSection6:Cell("RA_ADMISSA"):SetValue(_cRA_ADMISSA)	
			oSection6:Cell("RG_DATADEM"):SetValue(_cRG_DATADEM)
			oSection6:Cell("RG_DATAHOM"):SetValue(_cRG_DATAHOM)			
			oSection6:Cell("RG_DTAVISO"):SetValue(_cRG_DTAVISO)
			oSection6:Cell("RG_TIPORES"):SetValue(_cRG_TIPORES)
			oSection6:Cell("RG_DESCTPR"):SetValue(_cRG_DRES )
			oSection6:Cell("RG_SALMES"):SetValue(_cRG_SALMES)

			oSection6:Cell("RRR_1PD"):SetValue(_c1RR_PD)
			oSection6:Cell("RRV_1DESC"):SetValue(_c1RV_DESC)			
			oSection6:Cell("RRR_1VALOR"):SetValue(_c1RR_VALOR)	

			oSection6:Cell("RRR_2PD"):SetValue(_c2RR_PD)
			oSection6:Cell("RRV_2DESC"):SetValue(_c2RV_DESC)			
			oSection6:Cell("RRR_2VALOR"):SetValue(_c2RR_VALOR)	

			oSection6:Cell("RRR_3PD"):SetValue(_c3RR_PD)
			oSection6:Cell("RRV_3DESC"):SetValue(_c3RV_DESC)			
			oSection6:Cell("RRR_3VALOR"):SetValue(_c3RR_VALOR)	

			oSection6:Cell("RRR_4PD"):SetValue(_c4RR_PD)
			oSection6:Cell("RRV_4DESC"):SetValue(_c4RV_DESC)			
			oSection6:Cell("RRR_4VALOR"):SetValue(_c4RR_VALOR)	

			oSection6:Cell("RRR_5PD"):SetValue(_c5RR_PD)
			oSection6:Cell("RRV_5DESC"):SetValue(_c5RV_DESC)			
			oSection6:Cell("RRR_5VALOR"):SetValue(_c5RR_VALOR)	

			oSection6:PrintLine()

			_c1RR_PD := Space(4)
			_c1RV_DESC := Space(5)
			_c1RR_HORAS := Space(30)
			_c1RR_VALOR := Space(20)

			_c2RR_PD := Space(4)
			_c2RV_DESC := Space(5)
			_c2RR_HORAS := Space(30)
			_c2RR_VALOR := Space(20)

			_c3RR_PD := Space(4)
			_c3RV_DESC := Space(5)
			_c3RR_HORAS := Space(30)
			_c3RR_VALOR := Space(20)

			_c4RR_PD := Space(4)
			_c4RV_DESC := Space(5)
			_c4RR_HORAS := Space(30)
			_c4RR_VALOR := Space(20)

			_c5RR_PD := Space(4)
			_c5RV_DESC := Space(5)
			_c5RR_HORAS := Space(30)
			_c5RR_VALOR := Space(20)

		EndIf

	EndDo	
	oSection6:Finish()
	oReport:ThinLine()
EndIf

Return
