/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |22/03/2018| Chamado 43342. Retirada da função MTR900CUnf(lCusFil,lCusEmp). 
Lucas Borges  |12/09/2024| Chamado 48465. Removendo warning de compilação.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Jose Gavetti  |25/11/2025| Chamado 52778. Inclusão coluna Filial.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: REST012
Autor-------------: Totvs
Data da Criacao---: 25/07/2006                                 .
Descrição---------: Kardex fisico - financeiro - Trabalhando em segunda unidade de medida.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST012()

Local oReport

//Interface de impressao
oReport:= ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef()
Autor-------------: Totvs
Data da Criacao---: 25/07/2006                                 .
Descrição---------: A funcStaticatica ReportDef devera ser criada para todos os
                    relatorios que poderao ser agendados pelo usuario. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport 
Local oSection1
Local oSection2
Local oSection3
Local aOrdem      := {}
Local cPicB2Tot   := PesqPictQt("B2_VATU1",18)
Local cTamB2Tot   := TamSX3('B2_VATU1')[1]
Local cPicB2Qt    := PesqPictQt("B2_QATU" ,18)
Local cTamB2Qt    := TamSX3('B2_QATU')[1]
Local cPicB2Cust  := PesqPict("SB2","B2_CM1",18)
Local cTamB2Cust  := TamSX3('B2_CM1')[1]
Local cPicD1Qt    := PesqPict("SD1","D1_QUANT" ,18)
Local cTamD1Qt    := TamSX3('D1_QUANT')[1]
Local cPicD1Cust  := PesqPict("SD1","D1_CUSTO",18)
Local cTamD1Cust  := TamSX3('D1_CUSTO')[1]
Local cPicD2Qt    := PesqPict("SD2","D2_QUANT" ,18)
Local cTamD2Qt    := TamSX3('D2_QUANT')[1]
Local cPicD2Cust  := PesqPict("SD2","D2_CUSTO1",18)
Local cTamD2Cust  := TamSX3('D2_CUSTO1')[1]
Local cTamD1CF    := TamSX3('D1_CF')[1]
Local cTamCCPVPJOP:= TamSX3(MaiorCampo("D3_CC;D3_PROJPMS;D3_OP;D2_CLIENTE"))[1] 
Local lVEIC       := Upper(GetMV("MV_VEICULO"))=="S"
Local nTamData 	  := IIf(__SetCentury(),10,8)
Local lVer116     := (Val(GetVersao(.F.)) == 11 .And. GetRpoRelease() >= "R6" .Or. Val(GetVersao(.F.))  > 11)
Local _cTamFator   := TamSX3('B1_CONV')[1]
Local _cTamTipConv := TamSX3('B1_TIPCONV')[1]
Local _cPicFator   := PesqPict("SB1","B1_CONV",18)
Local _cPicTipconv := PesqPict("SB1","B1_TIPCONV",18)

//===============================================================\
// MV_CUSFIL - Parametro utilizado para verificar se o sistema   |
// utiliza custo unificado por:                                  |
//       F = Custo Unificado por Filial                          |
//       E = Custo Unificado por Empresa                         |
//       A = Custo Unificado por Armazem                         | 
//===============================================================/
Local lCusFil    := AllTrim(SuperGetMV('MV_CUSFIL' ,.F.,"A")) == "F"
Local lCusEmp    := AllTrim(SuperGetMv('MV_CUSFIL' ,.F.,"A")) == "E"


//================================================================
// MV_CUSREP - Parametro utilizado para habilitar o calculo do   
//             Custo de Reposicao.                               
//================================================================
Local lCusRep  := SuperGetMv("MV_CUSREP",.F.,.F.) .And. (FindFunction("MA330AvRep") .And. MA330AvRep())

//===========================================================================
// Criacao do componente de impressao                                      
//                                                                         
// TReport():New                                                           
// ExpC1 : Nome do relatorio                                               
// ExpC2 : Titulo                                                          
// ExpC3 : Pergunte                                                        
// ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  
// ExpC5 : Descricao                                                       
//                                                                        
//===========================================================================
oReport:= TReport():New("REST012","Kardex Fisico com Segunda Unidade Medida Qtd.","MTR900", {|oReport| ReportPrint(oReport)},"Este programa emitira uma relacao com as movimentacoes"+" "+"dos produtos selecionados, ordenados sequencialmente." )
oReport:SetLandscape()    
oReport:SetTotalInLine(.F.)

//===============================================================
// Verifica as perguntas selecionadas                      
//===============================================================
// Variaveis utilizadas para parametros                     
// MV_PAR01         // Do produto                           
// MV_PAR02         // Ate o produto                        
// MV_PAR03         // Do tipo                              
// MV_PAR04         // Ate o tipo                           
// MV_PAR05         // Da data                              
// MV_PAR06         // Ate a data                           
// MV_PAR07         // Lista produtos s/movimento           
// MV_PAR08         // Qual Local (almoxarifado)            
// MV_PAR09         // (d)OCUMENTO/(s)EQUENCIA              
// MV_PAR10         // moeda selecionada ( 1 a 5 )          
// MV_PAR11         // Seq.de Digitacao /Calculo            
// MV_PAR12         // Pagina Inicial                       
// MV_PAR13         // Lista Transf Locali (Sim/Nao)        
// MV_PAR14         // Do  Grupo                            
// MV_PAR15         // Ate o Grupo                          
// MV_PAR16         // Seleciona Filial?                    
// MV_PAR17         // Qual Custo ? ( Medio / Reposicao )   
//===============================================================
Pergunte("MTR900",.F.)

aAdd( aOrdem, " Codigo Produto " ) // " Codigo Produto "
aAdd( aOrdem, " Tipo do Produto" ) // " Tipo do Produto"

//===============================================================
// Definicao da Sessao 1 - Dados do Produto                     
//===============================================================
oSection1 := TRSection():New(oReport,"Produtos (Parte 1)",{"SB1","SB2"},aOrdem) //"Produtos (Parte 1)"
oSection1 :SetTotalInLine(.F.)
oSection1 :SetReadOnly()
oSection1 :SetLineStyle()

If lVeic
	TRCell():New(oSection1,"B1_CODITE","SB1",/*Titulo*/				     ,/*Picture*/,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
EndIf
TRCell():New(oSection1,"cProduto"	,"   ",/*Titulo*/					 ,/*Picture*/,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
oSection1:Cell("cProduto"):GetFieldInfo("B1_COD")
TRCell():New(oSection1,"B1_DESC"	,"SB1",/*Titulo*/					 ,/*Picture*/,30			,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_UM"		,"SB1","Um"						     ,/*Picture*/,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)

TRCell():New(oSection1,"FATOR"	    ,"SB1","Fat.Conv"			         ,_cPicFator  ,_cTamFator   ,/*lPixel*/,/*{|| code-block de impressao }*/) //=======================  FATOR DE CONVERSÃO 
TRCell():New(oSection1,"TIPOCONV"	,"SB1","Tip.Conv"			         ,_cPicTipconv,_cTamTipConv ,/*lPixel*/,/*{|| code-block de impressao }*/) //=======================  TIPO DE CONVERSÃO  

TRCell():New(oSection1,"cTipo"		,"   ","Tipo"						 ,"@!"		 ,2				,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_GRUPO"	,"SB1","Grupo"						 ,/*Picture*/,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"nCusMed"	,"   ",IIf(lCusRep .And. MV_PAR17==2 ,"Custo de Reposição ","Custo Medio")	,cPicB2Cust	,cTamB2Cust		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"nQtdSal"	,"   ","Qtd. Saldo"					 ,cPicB2Qt	 ,cTamB2Qt		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"nQtd2Un"	,"   ","Qtd.2 UN Sld"				 ,cPicB2Qt	 ,cTamB2Qt		,/*lPixel*/,/*{|| code-block de impressao }*/)  //=======================  QTD SEGUNDA UNID MEDIDA 

TRCell():New(oSection1,"nVlrSal"	,"   ","Vlr.Total Saldo"			 ,cPicB2Tot	 ,cTamB2Tot		,/*lPixel*/,/*{|| code-block de impressao }*/)
//===============================================================
// Definicao da Sessao 2 - Cont. dos dados do Produto           
//===============================================================
If lVer116
	oSection2 := TRSection():New(oSection1,"Produtos (Parte 2)",{"SB1","SB2","NNR"}) // "Produtos (Parte 2)"
Else
	oSection2 := TRSection():New(oSection1,"Produtos (Parte 2)",{"SB1","SB2"})       // "Produtos (Parte 2)"
EndIf	
oSection2 :SetTotalInLine(.F.)
oSection2 :SetReadOnly()
oSection2 :SetLineStyle()

If lVeic
	TRCell():New(oSection2	,"cProduto"		,"   ",/*Titulo*/	,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	oSection2:Cell("cProduto"):GetFieldInfo("B1_COD")
	TRCell():New(oSection2	,"B1_UM"		,"SB1","Um"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2	,"cTipo"		,"   ","Tipo"		,"@!"			,2			,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2	,"B1_GRUPO"		,"SB1","Grupo"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	
	TRCell():New(oSection2	,"FATOR"		,"SB1","Fat.Conv"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2	,"TIPOCONV"		,"SB1","Tip.Conv"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
EndIf	

TRCell():New(oSection2	,"B1_POSIPI"	,"SB1","POSICAO IPI"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)	
If lVer116
	TRCell():New(oSection2		,'NNR_DESCRI'	,"NNR","ENDERECO"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,{|| If(lCusFil .Or. lCusEmp , MV_PAR08 , Posicione("NNR",1,xFilial("NNR")+MV_PAR08,"NNR_DESCRI")) })
Else
	TRCell():New(oSection2		,"B2_LOCALIZ"	,"SB2","ENDERECO"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,{|| If(lCusFil .Or. lCusEmp , MV_PAR08 , SB2->B2_LOCALIZ) })
EndIf
TRCell():New(oSection2	,"D1_FILIAL"	,"  ","FILIAL"		,/*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

//===============================================================
// Definicao da Sessao 3 - Movimentos                           
//===============================================================
oSection3 := TRSection():New(oSection2,"Movimentação dos produtos",{"SD1","SD2","SD3"}) //"Movimentação dos Produtos"
oSection3 :SetHeaderPage()
oSection3 :SetTotalInLine(.F.)
oSection3 :SetTotalText("T O T A I S  :") //"T O T A I S  :"
oSection3 :SetReadOnly()

TRCell():New(oSection3,"dDtMov"		,"   ","OPERACAO"+CRLF+"DATA"	,/*Picture*/,nTamData		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTES"		,"   ","TES"				,"@!"		,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cCF"		,"   ","C.F"				,"@!"		,cTamD1CF		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cDoc"		,"   ","DOCUMENTO"+CRLF+"NUMERO"	,"@!"		,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTraco1"	,"   ","|"+CRLF+"|"			,/*Picture*/,1		   		,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nENTQtd"	,"   ","ENTRADAS"+CRLF+"QUANTIDADE"	,cPicD1Qt	,cTamD1Qt  		,/*lPixel*/,/*{|| code-block de impressao }*/)

TRCell():New(oSection3,"nENT2UnQtd"	,"   ","ENTRADAS"+CRLF+"QTD 2 UNID",cPicD1Qt	,cTamD1Qt  		,/*lPixel*/,/*{|| code-block de impressao }*/) //=======================  QTD SEGUNDA UNID MEDIDA 

TRCell():New(oSection3,"cTraco2"	,"   ","|"+CRLF+"|"			,/*Picture*/,1		   		,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nENTCus"	,"   ","ENTRADAS"+CRLF+"CUSTO TOTAL"	,cPicD1Cust	,cTamD1Cust		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTraco3"	,"   ","|"+CRLF+"|"			,/*Picture*/,1		   		,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nCusMov"	,"   ","CUSTO MEDIO"+CRLF+"DO MOVIMENTO"	,cPicB2Cust	,cTamB2Cust		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTraco4"	,"   ","|"+CRLF+"|"			,/*Picture*/,1		   		,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nSAIQtd"	,"   ","SAIDAS"+CRLF+"QUANTIDADE"	,cPicD2Qt	,cTamD2Qt		,/*lPixel*/,/*{|| code-block de impressao }*/)

TRCell():New(oSection3,"nSAI2UnQtd"	,"   ","SAIDAS"+CRLF+"QTD 2 UNID"	,cPicD2Qt	,cTamD2Qt		,/*lPixel*/,/*{|| code-block de impressao }*/) //=======================  QTD SEGUNDA UNID MEDIDA 

TRCell():New(oSection3,"cTraco5"	,"   ","|"+CRLF+"|"			,/*Picture*/,1				,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nSAICus"	,"   ","SAIDAS"+CRLF+"CUSTO TOTAL"	,cPicD2Cust	,cTamD2Cust		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTraco6"	,"   ","|"+CRLF+"|"			,/*Picture*/,1				,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nSALDQtd"	,"   ","SALDO" +CRLF+"QUANTIDADE"	,cPicB2Qt	,cTamB2Qt		,/*lPixel*/,/*{|| code-block de impressao }*/)

TRCell():New(oSection3,"nSALD2UnQtd","   ","SALDO" +CRLF+"QTD 2 UNID"	,cPicB2Qt	,cTamB2Qt		,/*lPixel*/,/*{|| code-block de impressao }*/) //=======================  QTD SEGUNDA UNID MEDIDA 

TRCell():New(oSection3,"cTraco7"	,"   ","|"+CRLF+"|"			,/*Picture*/,1				,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"nSALDCus"	,"   ","SALDO" +CRLF+"VALOR TOTAL"	,cPicB2Tot	,cTamB2Tot		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection3,"cTraco8"	,"   ","|"+CRLF+"|"			,/*Picture*/,1		   		,/*lPixel*/,{|| "|" })
TRCell():New(oSection3,"cCCPVPJOP"	,"   ","CLI,For,"+CRLF+"CC , PJ ou OP"  ,"@!"		,cTamCCPVPJOP+2 ,/*lPixel*/,/*{|| code-block de impressao }*/)

// Definir o formato de valores negativos (para o caso de devolucoes)
oSection3:Cell("nENTQtd"):SetNegative("PARENTHESES")
oSection3:Cell("nENTCus"):SetNegative("PARENTHESES")
oSection3:Cell("nSAIQtd"):SetNegative("PARENTHESES")
oSection3:Cell("nSAICus"):SetNegative("PARENTHESES")
oSection3:Cell("nENT2UnQtd"):SetNegative("PARENTHESES")
oSection3:Cell("nSAI2UnQtd"):SetNegative("PARENTHESES")

TRFunction():New(oSection3:Cell("nENTQtd")	 ,NIL,"SUM"		,/*oBreak*/,"",cPicD1Qt		,{|| oSection3:Cell("nENTQtd"):GetValue(.T.) },.T.,.F.)
TRFunction():New(oSection3:Cell("nENT2UnQtd"),NIL,"SUM"		,/*oBreak*/,"",cPicD1Qt		,{|| oSection3:Cell("nENT2UnQtd"):GetValue(.T.) },.T.,.F.)
TRFunction():New(oSection3:Cell("nENTCus")	 ,NIL,"SUM"		,/*oBreak*/,"",cPicD1Cust	,{|| oSection3:Cell("nENTCus"):GetValue(.T.) },.T.,.F.)

TRFunction():New(oSection3:Cell("nSAIQtd")	,NIL,"SUM"		,/*oBreak*/,"",cPicD2Qt		,{|| oSection3:Cell("nSAIQtd"):GetValue(.T.) },.T.,.F.)
TRFunction():New(oSection3:Cell("nSAI2UnQtd"),NIL,"SUM"		,/*oBreak*/,"",cPicD2Qt		,{|| oSection3:Cell("nSAI2UnQtd"):GetValue(.T.) },.T.,.F.)
TRFunction():New(oSection3:Cell("nSAICus")	,NIL,"SUM"		,/*oBreak*/,"",cPicD2Cust	,{|| oSection3:Cell("nSAICus"):GetValue(.T.) },.T.,.F.)

TRFunction():New(oSection3:Cell("nSALDQtd"),NIL,"ONPRINT"	,/*oBreak*/,"",cPicB2Qt		,{|| oSection3:Cell("nSALDQtd"):GetValue(.T.) },.T.,.F.)
TRFunction():New(oSection3:Cell("nSALD2UnQtd"),NIL,"ONPRINT",/*oBreak*/,"",cPicB2Tot	,{|| oSection3:Cell("nSALD2UnQtd"):GetValue(.T.) },.T.,.F.)
TRFunction():New(oSection3:Cell("nSALDCus"),NIL,"ONPRINT"	,/*oBreak*/,"",cPicB2Tot	,{|| oSection3:Cell("nSALDCus"):GetValue(.T.) },.T.,.F.)

oSection3:SetNoFilter("SD1")
oSection3:SetNoFilter("SD2")
oSection3:SetNoFilter("SD3")

Return(oReport)

/*
===============================================================================================================================
Programa----------:  ReportPrint(oReport)
Autor-------------: Totvs
Data da Criacao---: 25/07/2006                                 .
Descrição---------: Define a estrutura de dados do relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport)

Static lIxbConTes := NIL

Local oSection1 := oReport:Section(1) 
Local oSection2 := oReport:Section(1):Section(1)  
Local oSection3 := oReport:Section(1):Section(1):Section(1)  
Local nOrdem    := oReport:Section(1):GetOrder() 
Local cSelectD1 := '', cWhereD1 := '', cWhereD1C := ''
Local cSelectD2 := '', cWhereD2 := '', cWhereD2C := ''
Local cSelectD3 := '', cWhereD3 := '', cWhereD3C := ''
Local cSelectVe := '%%', cUnion := '%%'
Local aDadosTran:= {}
Local lContinua := .F.
Local lFirst    := .T. 
Local lTransEnd := .T.
Local aSalAtu   := { 0,0,0,0,0,0,0 }
Local cPicB2Qt2 := PesqPictQt("B2_QTSEGUM" ,18)
Local cTRBSD1	:= CriaTrab(,.F.)
Local cTRBSD2	:= Subs(cTrbSD1,1,7)+"A"
Local cTRBSD3	:= Subs(cTrbSD1,1,7)+"B"
Local cSeqIni 	:= Replicate("z",6)
Local nRegTr    := 0
Local nTotRegs  := 0
Local nInd      := 0
Local cProdAnt  := ""
Local cLocalAnt := ""
Local cIndice	:= ""
Local cCampo1   := ""
Local cCampo2   := ""
Local cCampo3   := ""
Local cCampo4   := ""
Local cNumSeqTr := "" 
Local cAlias    := ""
Local cTipoNf   := ""
// Indica se esta listando relatorio do almox. de processo
Local lLocProc  := AllTrim(MV_PAR08) == GetMv("MV_LOCPROC")
// Indica se deve imprimir movimento invertido (almox. de processo)
Local lInverteMov :=.F.
Local lPriApropri :=.T.
//=================================================================
// Verifica se existe ponto de entrada                          
//=================================================================
Local lTesNEst := .F.

//=================================================================
// Codigo do produto importado - NAO DEVE SER LISTADO           
//=================================================================
Local cProdImp := GetMV("MV_PRODIMP")

Local cWhereB1A:= " " 
Local cWhereB1B:= " " 
Local cWhereB1C:= " " 
Local cWhereB1D:= " " 

Local cQueryB1A:= " " 
Local cQueryB1B:= " " 
Local cQueryB1C:= " " 
Local cQueryB1D:= " " 

//=================================================================
// Concessionaria de Veiculos                                   
//=================================================================
Local lVEIC    := Upper(GetMV("MV_VEICULO"))=="S"

Local lImpSMov := .F.
Local lImpS3   := .F.
Local cProdMNT := GetMv("MV_PRODMNT")
Local cProdTER := GetMv("MV_PRODTER")
Local aProdsMNT := {}

//=================================================================
// Variaveis utilizadas para processamento de Filiais           
//=================================================================
Local aFilsCalc := MatFilCalc( IIf (!IsBlind(), MV_PAR16 == 1, .F.))
Local cFilBack  := cFilAnt
Local nForFilial:= 0

//=================================================================
// Variavel utilizada para inicar a pagina do relatorio
//=================================================================
Local n_pag     := MV_PAR12
Local cAliasTop := ""
Local cCondicao := ""  
Local cFilUsrSB1:= oSection1:GetAdvplExp("SB1")
Local cFilUsrSB2:= oSection1:GetAdvplExp("SB2")
Local lWmsNew		:= SuperGetMv("MV_WMSNEW",.F.,.F.)
Local lD3Servi	:= IIf(lWmsNew,.F.,GetMV('MV_D3SERVI',.F.,'N')=='N')
Local _cCodMoeda := GetMv("MV_SIMB"+Ltrim(Str(MV_PAR10))) 
Local _lPE_MTAAVLTES := ExistBlock("MTAAVLTES")
Local _cEstornD3 := SuperGetMV('MV_D3ESTOR', .F., 'N')
Local _cCrtlQualit := SuperGetMV('MV_CQ', .F., '98')

#IFDEF TOP  
	If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
		cAliasTop := GetNextAlias()
	Else
#EndIf 
	cCondicao := ""
#IFDEF TOP
	EndIf
#EndIf

Private bBloco   := { |nV,nX| Trim(nV)+IIf(ValType(nX)='C',"",Str(nX,1)) }

//=================================================================
// MV_CUSREP - Parametro utilizado para habilitar o calculo do   
//             Custo de Reposicao.                               
//=================================================================
Private lCusRep  := SuperGetMv("MV_CUSREP",.F.,.F.) .And. (FindFunction("MA330AvRep") .And. MA330AvRep())

cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
cProdTER := cProdTER + Space(15-Len(cProdTER))

//=================================================================
//     MV_CUSFIL - Parametro utilizado para verificar se o sistema   
//                 utiliza custo unificado por:                                  
//               F = Custo Unificado por Filial                          
//               E = Custo Unificado por Empresa                         
//               A = Custo Unificado por Armazem                          
//=================================================================
Private lCusFil    := AllTrim(SuperGetMV('MV_CUSFIL' ,.F.,"A")) == "F"
Private lCusEmp    := AllTrim(SuperGetMv('MV_CUSFIL' ,.F.,"A")) == "E"

lCusFil:=lCusFil .And. MV_PAR08 == Repl("*",TamSX3("B2_LOCAL")[1])
lCusEmp:=lCusEmp .And. MV_PAR08 == Repl("#",TamSX3("B2_LOCAL")[1])

Private lDev := .F. // Flag que indica se nota ‚ devolu‡ao (.T.) ou nao (.F.)

oReport:SetPageNumber(n_pag)
//=================================================================
// Alerta o usuario que o custo de reposicao esta desativado.   
//=================================================================

If MV_PAR17==2 .And. !lCusRep
	Help(" ",1,"A910CUSRP")
	MV_PAR17 := 1
EndIf

//=================================================================
// aFilsCalc - Array com filiais a serem processadas            
//=================================================================
If !Empty(aFilsCalc)

	For nForFilial := 1 To Len( aFilsCalc )
	
		If aFilsCalc[ nForFilial, 1 ]
		
			cFilAnt := aFilsCalc[ nForFilial, 2 ]

			oReport:EndPage() //Reinicia Pagina
			
			oReport:SetTitle(OemToAnsi("KARDEX FISICO-FINANCEIRO ") + If(MV_PAR11==3,"(DATA DE MOVIMENTO)",If(MV_PAR11==1,;
			                                                              If(lCusRep .And. MV_PAR17==2,"(SEQUENCIA/REPOSIÇÃO)","(SEQUENCIA)"),IIf(lCusRep .And. MV_PAR17==2,"(CALCULO/REPOSIÇÃO) " ,"(SEQUENCIA)") ) )+;
			                                                        " " + IIf(lCusFil .Or. lCusEmp,"",OemToAnsi("L O C A L :")+" "+mv_par08) ) // "KARDEX FISICO-FINANCEIRO "###"(SEQUENCIA)"###"(CALCULO)"###"L O C A L :"
			If nOrdem == 1				
			   oReport:SetTitle( oReport:Title()+AllTrim(" (Por "+" Codigo Produto "+" ,em "+AllTrim(_cCodMoeda)+")")+' - ' + aFilsCalc[ nForFilial, 3 ] ) //" (Por "###" ,em "	
			Else
			   oReport:SetTitle( oReport:Title()+AllTrim(" (Por "+" Tipo do Produto"+" ,em "+AllTrim(_cCodMoeda)+")")+' - ' + aFilsCalc[ nForFilial, 3 ] ) //" (Por "###" ,em "
			EndIf
				
			If lVeic
				oSection1:Cell("cProduto"	):Disable()
				oSection1:Cell("B1_UM"		):Disable()
				oSection1:Cell("cTipo"		):Disable()
				oSection1:Cell("B1_GRUPO"	):Disable()
			EndIf
				
			If MV_PAR09 $ "Ss"
				oSection3:Cell("cDoc"):SetTitle("SEQUENCIA"+CRLF+"NUMERO") //"SEQUENCIA"
			EndIf	

			DBSelectArea("SD1")   // Itens de Entrada
			nTotRegs += LastRec()
			
			DBSelectArea("SD2")   // Itens de Saida
			nTotRegs += LastRec()
			
			DBSelectArea("SD3")   // movimentacoes internas (producao/requisicao/devolucao)
			nTotRegs += LastRec()
			
			DBSelectArea("SB2")  // Saldos em estoque
			DBSetOrder(1)
			nTotRegs += LastRec()
			
			//===========================================================================
			// MTAAVLTES - Ponto de Entrada executado durante a montagem do relatorio  
			//             para verificar se devera considerar TES que nao atualiza    
			//             saldos em estoque.                                          
			//===========================================================================
			lIxbConTes := If(lIxbConTes == NIL,_lPE_MTAAVLTES,lIxbConTes)

			//===========================================================================
			// Filtragem do relatorio                                                  
			//===========================================================================
			#IFDEF TOP
				If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
				   //===========================================================================
				   // Transforma parametros Range em expressao SQL                     	
				   //===========================================================================
				   MakeSqlExpr(oReport:uParam)
				 
				   //===========================================================================
				   // Query do relatorio da secao 1                                           
				   //===========================================================================
				   oReport:Section(1):BeginQuery()	
				
				   //===========================================================================
				   // Complemento do SELECT da tabela SD1                                     
				   //===========================================================================
				   If lCusRep .And. MV_PAR17==2
					  cSelectD1 := "% D1_CUSRP"
					  cSelectD1 += Str(MV_PAR10,1,0) // Coloca a Moeda do Custo
				   Else
					  cSelectD1 := "% D1_CUSTO"
					  If MV_PAR10 > 1
						 cSelectD1 += Str(MV_PAR10,1,0) // Coloca a Moeda do Custo
					  EndIf
				   EndIf	
				   cSelectD1 += " CUSTO,"
				   cSelectD1 += "%"
				   //===========================================================================
				   // Complemento do SELECT da tabela SB1 para MV_VEICULO                     
				   //===========================================================================
				   cSelectVe := "%" 
				   cSelectVe += ","
				   If lVEIC
				      cSelectVe += "SB1.B1_CODITE B1_CODITE,"
				   EndIf
				   cSelectVe += "%" 
				   //===========================================================================
				   // Complemento do Where da tabela SD1                                      
				   //===========================================================================
				   cWhereD1 := "%" 
				   cWhereD1 += "AND" 
				   If !(lCusFil .Or. lCusEmp)
					  cWhereD1 += " D1_LOCAL = '" + MV_PAR08 + "' AND"
			       EndIf
				   cWhereD1 += "%" 
				   //===========================================================================
				   // Complemento do Where da tabela SD1 (Tratamento Filial)                 
				   //===========================================================================
				    If lCusEmp
					   If !Empty(xFilial("SD1")) .And. !Empty(xFilial("SF4"))
						  cWhereD1C := "%"
						  cWhereD1C += " D1_FILIAL = F4_FILIAL AND "
						  cWhereD1C += "%"
					   Else
						  cWhereD1C := "% %"
					   EndIf	
				    Else
					   cWhereD1C := "%"
					   cWhereD1C += " D1_FILIAL ='" + xFilial("SD1") + "' AND "
					   cWhereD1C += " SF4.F4_FILIAL = '" + xFilial("SF4") + "' AND"
					   cWhereD1C += "%"
				    EndIf	
				
				    //===========================================================================
				    // Complemento do SELECT da tabela SD2                                     
				    //===========================================================================
				    If lCusRep .And. MV_PAR17==2
				       cSelectD2 := "% D2_CUSRP"
					   cSelectD2 += Str(MV_PAR10,1,0) // Coloca a Moeda do Custo
				    Else
				       cSelectD2 := "% D2_CUSTO"
					   cSelectD2 += Str(MV_PAR10,1,0) // Coloca a Moeda do Custo
				    EndIf	
				    cSelectD2 += " CUSTO,"
			        cSelectD2 += "%"	
				
				//===========================================================================
				// Complemento do Where da tabela SD1                                      
				//===========================================================================
				cWhereD2 := "%" 
				cWhereD2 += "AND" 
				If !(lCusFil .Or. lCusEmp)
					cWhereD2 += " D2_LOCAL = '" + MV_PAR08 + "' AND"
				EndIf
				cWhereD2 += "%"    
				
				//===========================================================================
				// Complemento do Where da tabela SD2 (Tratamento Filial)                  
				//===========================================================================
				If lCusEmp
					If !Empty(xFilial("SD2")) .And. !Empty(xFilial("SF4"))
						cWhereD2C := "%"
						cWhereD2C += " D2_FILIAL = F4_FILIAL AND "
						cWhereD2C += "%"
					Else
						cWhereD2C := "% %"
					EndIf	
				Else
					cWhereD2C := "%"
					cWhereD2C += " D2_FILIAL ='" + xFilial("SD2") + "' AND "
					cWhereD2C += " SF4.F4_FILIAL = '" + xFilial("SF4") + "' AND"
					cWhereD2C += "%"
				EndIf	
				
				//===========================================================================
				// Complemento do SELECT da tabelas SD3                                    
				//===========================================================================
				If lCusRep .And. MV_PAR17==2
					cSelectD3 := "% D3_CUSRP"
					cSelectD3 += Str(MV_PAR10,1,0) // Coloca a Moeda do Custo
				Else
					cSelectD3 := "% D3_CUSTO"
					cSelectD3 += Str(MV_PAR10,1,0) // Coloca a Moeda do Custo
				EndIf	
				cSelectD3 +=	" CUSTO," 
				cSelectD3 += "%"    
				
				//===========================================================================
				// Complemento do WHERE da tabela SD3                                      
				//===========================================================================
			    cWhereD3 := "%"
				If _cEstornD3 == 'N' 
					cWhereD3 += " D3_ESTORNO <> 'S' AND"
				EndIf
				If lD3Servi .And. IntDL()
					cWhereD3 += " ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
					cWhereD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+_cCrtlQualit+"') ) AND"
				EndIf
				If !(lCusFil .Or. lCusEmp) .And. !lLocProc
					cWhereD3 += " D3_LOCAL = '"+MV_PAR08+"' AND" 
				EndIf
				If	!lVEIC
					cWhereD3+= " SB1.B1_COD >= '"+MV_PAR01+"' AND SB1.B1_COD <= '"+MV_PAR02+"' AND"
				Else
					cWhereD3+= " SB1.B1_CODITE >= '"+MV_PAR01+"' AND SB1.B1_CODITE <= '"+MV_PAR02+"' AND"
				EndIf	
				If lCusEmp
					cWhereD3 += " SB1.B1_TIPO >= '"+MV_PAR03+"' AND SB1.B1_TIPO <= '"+MV_PAR04+"' AND"
				Else
					cWhereD3 += " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+MV_PAR03+"' AND SB1.B1_TIPO <= '"+MV_PAR04+"' AND"
				EndIf
				cWhereD3 += " SB1.B1_GRUPO >= '"+MV_PAR14+"' AND SB1.B1_GRUPO <= '"+MV_PAR15+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
				cWhereD3 += " SB1.D_E_L_E_T_=' ' AND"
				cWhereD3 += "%"	
				//===========================================================================
				// Complemento do Where da tabela SD3 (Tratamento Filial)                  
				//===========================================================================
				If lCusEmp
					cWhereD3C := "% %"
				Else
					cWhereD3C := "%"
					cWhereD3C += " D3_FILIAL ='" + xFilial("SD3")  + "' AND "
					cWhereD3C += "%"
				EndIf	
				
				//===========================================================================
				// Complemento do WHERE da tabela SB1 para todos os selects                
				//===========================================================================
				cWhereB1A:= "%" 
			   	cWhereB1B:= "%" 
			    cWhereB1C:= "%" 
			    cWhereB1D:= "%" 	
				If	!lVEIC
					cWhereB1A+= " AND SB1.B1_COD >= '"+MV_PAR01+"' AND SB1.B1_COD <= '"+MV_PAR02+"'"
					cWhereB1B+= " AND SB1.B1_COD = SB1EXS.B1_COD"
					If lCusEmp
						cWhereB1C+= " SB1.B1_TIPO >= '"+MV_PAR03+"' AND SB1.B1_TIPO <= '"+MV_PAR04+"' AND"
						cWhereB1D+= " SB1EXS.B1_COD >= '"+MV_PAR01+"' AND SB1EXS.B1_COD <= '"+MV_PAR02+"' AND SB1EXS.B1_TIPO >= '"+MV_PAR03+"' AND SB1EXS.B1_TIPO <= '"+MV_PAR04+"' AND"
					Else
						cWhereB1C+= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+MV_PAR03+"' AND SB1.B1_TIPO <= '"+MV_PAR04+"' AND"
						cWhereB1D+= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_COD >= '"+MV_PAR01+"' AND SB1EXS.B1_COD <= '"+MV_PAR02+"' AND SB1EXS.B1_TIPO >= '"+MV_PAR03+"' AND SB1EXS.B1_TIPO <= '"+MV_PAR04+"' AND"
					EndIf	
				Else
					cWhereB1A+= " AND SB1.B1_CODITE >= '"+MV_PAR01+"' AND SB1.B1_CODITE <= '"+MV_PAR02+"'"
					cWhereB1B+= " AND SB1.B1_COD = SB1EXS.B1_COD"
					If lCusEmp
						cWhereB1C+= " SB1.B1_TIPO >= '"+MV_PAR03+"' AND SB1.B1_TIPO <= '"+MV_PAR04+"' AND"
						cWhereB1D+= " SB1EXS.B1_CODITE >= '"+MV_PAR01+"' AND SB1EXS.B1_CODITE <= '"+MV_PAR02+"' AND SB1EXS.B1_TIPO >= '"+MV_PAR03+"' AND SB1EXS.B1_TIPO <= '"+MV_PAR04+"' AND"
					Else
						cWhereB1C+= " SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_TIPO >= '"+MV_PAR03+"' AND SB1.B1_TIPO <= '"+MV_PAR04+"' AND"
						cWhereB1D+= " SB1EXS.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1EXS.B1_CODITE >= '"+MV_PAR01+"' AND SB1EXS.B1_CODITE <= '"+MV_PAR02+"' AND SB1EXS.B1_TIPO >= '"+MV_PAR03+"' AND SB1EXS.B1_TIPO <= '"+MV_PAR04+"' AND"
					EndIf	
				EndIf	
			
				cWhereB1C += " SB1.B1_GRUPO >= '"+MV_PAR14+"' AND SB1.B1_GRUPO <= '"+MV_PAR15+"' AND SB1.B1_COD <> '"+cProdimp+"' AND "
				cWhereB1C += " SB1.D_E_L_E_T_=' '"
				cWhereB1D += " SB1EXS.B1_GRUPO >= '"+MV_PAR14+"' AND SB1EXS.B1_GRUPO <= '"+MV_PAR15+"' AND SB1EXS.B1_COD <> '"+cProdimp+"' AND "
				cWhereB1D += " SB1EXS.D_E_L_E_T_=' '"	
				
				cQueryB1A:= Subs(cWhereB1A,2)
				cQueryB1B:= Subs(cWhereB1B,2)
				cQueryB1C:= Subs(cWhereB1C,2)
				cQueryB1D:= Subs(cWhereB1D,2)
				
				cWhereB1A+= "%" 
			   	cWhereB1B+= "%" 
			    cWhereB1C+= "%" 
			    cWhereB1D+= "%" 	
			 	//===========================================================================
				// So inclui as condicoes a seguir qdo lista produtos sem 
				// movimento                                              
				//===========================================================================
				cQueryD1 := " FROM "
				cQueryD1 += RetSqlName("SB1") + " SB1"
				cQueryD1 += (", " + RetSqlName("SD1")+ " SD1 ")
				cQueryD1 += (", " + RetSqlName("SF4")+ " SF4 ")
				cQueryD1 += " WHERE SB1.B1_COD = D1_COD"
				If lCusEmp
					If !Empty(xFilial("SD1")) .And. !Empty(xFilial("SF4"))
						cQueryD1 += " AND F4_FILIAL = D1_FILIAL "
					EndIf	
				Else
					cQueryD1 += (" AND D1_FILIAL = '" + xFilial("SD1")+"'" )
					cQueryD1 += (" AND F4_FILIAL = '" + xFilial("SF4") + "'")
				EndIf	
				cQueryD1 += (" AND SD1.D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S'")
				cQueryD1 += (" AND D1_DTDIGIT >= '" + DToS(MV_PAR05) + "'")
				cQueryD1 += (" AND D1_DTDIGIT <= '" + DToS(MV_PAR06) + "'")
				cQueryD1 +=  " AND D1_ORIGLAN <> 'LF'"
				If !(lCusFil .Or. lCusEmp)
					cQueryD1 += " AND D1_LOCAL = '" + MV_PAR08 + "'"
				EndIf
				cQueryD1 += " AND SD1.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"
				
				cQueryD2 := " FROM "
				cQueryD2 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD2")+ " SD2 , "+ RetSqlName("SF4")+" SF4 "
				cQueryD2 += " WHERE SB1.B1_COD = D2_COD "
				If lCusEmp
					If !Empty(xFilial("SD2")) .And. !Empty(xFilial("SF4"))
						cQueryD2 += " AND F4_FILIAL = D2_FILIAL "
					EndIf	
				Else
					cQueryD2 += " AND D2_FILIAL = '"+xFilial("SD2")+"' "
					cQueryD2 += " AND F4_FILIAL = '"+xFilial("SF4")+"' " 
				EndIf	
				cQueryD2 += " AND SD2.D2_TES = F4_CODIGO AND F4_ESTOQUE = 'S'"
				cQueryD2 += " AND D2_EMISSAO >= '"+DToS(MV_PAR05)+"' AND D2_EMISSAO <= '"+DToS(MV_PAR06)+"'"
				cQueryD2 += " AND D2_ORIGLAN <> 'LF'"
				If !(lCusFil .Or. lCusEmp)
					cQueryD2 += " AND D2_LOCAL = '"+MV_PAR08+"'"
				EndIf
				cQueryD2 += " AND SD2.D_E_L_E_T_=' ' AND SF4.D_E_L_E_T_=' '"	
				
				cQueryD3 := " FROM "
				cQueryD3 += RetSqlName("SB1") + " SB1 , "+ RetSqlName("SD3")+ " SD3 "
				cQueryD3 += " WHERE SB1.B1_COD = D3_COD " 
				If !lCusEmp
					cQueryD3 += " AND D3_FILIAL = '"+xFilial("SD3")+"' "
				EndIf	
				cQueryD3 += " AND D3_EMISSAO >= '"+DToS(MV_PAR05)+"' AND D3_EMISSAO <= '"+DToS(MV_PAR06)+"'"
				If _cEstornD3 == 'N'
					cQueryD3 += " AND D3_ESTORNO <> 'S'"
				EndIf
				If lD3Servi .And. IntDL()
					cQueryD3 += " AND ( (D3_SERVIC = '   ') OR (D3_SERVIC <> '   ' AND D3_TM <= '500')  "
					cQueryD3 += " OR  (D3_SERVIC <> '   ' AND D3_TM > '500' AND D3_LOCAL ='"+_cCrtlQualit+"') )"					
				EndIf					
				If !(lCusFil .Or. lCusEmp) .And. !lLocProc
					cQueryD3 += " AND D3_LOCAL = '"+MV_PAR08+"'"
				EndIf
				cQueryD3 += " AND SD3.D_E_L_E_T_=' '"	
				
				cQuerySub:= "SELECT 1 "
				
				If MV_PAR07 == 1
					cQuery2 := " AND NOT EXISTS (" + cQuerySub + cQueryD1
					cQuery2 += cQueryB1B
					cQuery2 += " AND "
					cQuery2 += cQueryB1C
					cQuery2 += ") AND NOT EXISTS ("
					cQuery2 += cQuerySub + cQueryD2
					cQuery2 += cQueryB1B
					cQuery2 += " AND "
					cQuery2 += cQueryB1C
					cQuery2 += ") AND NOT EXISTS ("
					cQuery2 += cQuerySub + cQueryD3
					cQuery2 += cQueryB1B
					cQuery2 += " AND "
					cQuery2 += cQueryB1C + ")"
			        
					cUnion := "%"
					cUnion += " UNION SELECT 'SB1'"		// 01
					cUnion += ", SB1EXS.B1_COD"			// 02
					cUnion += ", SB1EXS.B1_TIPO"		// 03
					cUnion += ", SB1EXS.B1_UM"			// 04
					cUnion += ", SB1EXS.B1_GRUPO"		// 05
					cUnion += ", SB1EXS.B1_DESC"		// 06
					cUnion += ", SB1EXS.B1_POSIPI"		// 07
					cUnion += ", ''"					// 08
					cUnion += ", ''"					// 09
					cUnion += ", ''"					// 10
					cUnion += ", ''"					// 11
					cUnion += ", ''"					// 12
					cUnion += ", ''"					// 13
					cUnion += ", ''"					// 14
					cUnion += ", 0"						// 15
					cUnion += ", 0"						// 16
					cUnion += ", ''"					// 17
					cUnion += ", ''"					// 18
					cUnion += ", ''"					// 19
					cUnion += ", ''"					// 20
					cUnion += ", ''"					// 21
					cUnion += ", ''"					// 22
					cUnion += ", ''"					// 23
					cUnion += ", ''"					// 24
					cUnion += ", 0"						// 25
					cUnion += ", ''"					// 26
					cUnion += ", ''"					// 27
					If lVEIC
						cUnion += ", SB1EXS.B1_CODITE CODITE"	// 28
					EndIf		
					cUnion += ", 0"								// 29		   
					cUnion += ", SB1EXS.B1_CONV FATOR "        	// 30 // Fator conversao 
                    cUnion += ", SB1EXS.B1_TIPCONV TIPOCONV "   // 31 // Tipo conversao
					cUnion += ", SB1EXS.B1_FILIAL FILIAL "     	// 32 // Filial   
                    
					cUnion += " FROM "+RetSqlName("SB1") + " SB1EXS WHERE"
					cUnion += cQueryB1D
					cUnion += cQuery2
					cUnion += "%"
				EndIf
				
				cOrder := "%"
				If ! lVEIC
					If nOrdem == 1 //" Codigo Produto "###" Tipo do Produto"
						cOrder += " 2,"
					ElseIf nOrdem == 2
						cOrder += " 3,2,"
					EndIf
				Else
					If nOrdem ==1 //" Codigo Produto "###" Tipo do Produto"
						cOrder += " 28, 2, 5," 	// B1_CODITE, B1_COD, B1_GRUPO
					ElseIf nOrdem == 2
						cOrder += " 3, 28, 2, 5," // B1_TIPO, B1_CODITE, B1_COD, B1_GRUPO
					EndIf
				EndIf
			
				If MV_PAR11 == 1
//					cOrder += "17,12"+IIf(lVEIC,',29',',28')
					cOrder += "12"+IIf(lVEIC,',29',',28')
				ElseIf MV_PAR11 == 3
					cOrder += "9"+IIf(lVEIC,',29',',28')
				Else
					If lCusFil .Or. lCusEmp
						cOrder += "8,12"+IIf(lVEIC,',29',',28')
					Else
//						cOrder += "17,8,12"+IIf(lVEIC,',29',',28')
						cOrder += "8"+IIf(lVEIC,',29',',28')
					EndIf
				EndIf	
				cOrder += "%"
				
				BeginSql Alias cAliasTop
				
					SELECT 	'SD1' ARQ, 				//-- 01 ARQ
							 SB1.B1_COD PRODUTO, 	//-- 02 PRODUTO
							 SB1.B1_TIPO TIPO, 		//-- 03 TIPO
							 SB1.B1_UM,   			//-- 04 UM
							 SB1.B1_GRUPO,      	//-- 05 GRUPO
							 SB1.B1_DESC,      		//-- 06 DESCR
						     SB1.B1_POSIPI, 		//-- 07
						     D1_SEQCALC SEQCALC,    //-- 08
							 D1_DTDIGIT DATA,		//-- 09 DATA
							 D1_TES TES,			//-- 10 TES
							 D1_CF CF,				//-- 11 CF
							 D1_NUMSEQ SEQUENCIA,	//-- 12 SEQUENCIA
							 D1_DOC DOCUMENTO,		//-- 13 DOCUMENTO
							 D1_SERIE SERIE,		//-- 14 SERIE
							 D1_QUANT QUANTIDADE,	//-- 15 QUANTIDADE
							 D1_QTSEGUM QUANT2UM,	//-- 16 QUANT2UM
							 D1_LOCAL ARMAZEM,		//-- 17 ARMAZEM
				             ' ' PROJETO,			//-- 18 PROJETO
							 ' ' OP,				//-- 19 OP
							 ' ' CC,				//-- 20 OP
							 D1_FORNECE FORNECEDOR,	//-- 21 FORNECEDOR
							 D1_LOJA LOJA,			//-- 22 LOJA
							 ' ' PEDIDO,            //-- 23 PEDIDO
							 D1_TIPO TIPONF,		//-- 24 TIPO NF
							 %Exp:cSelectD1%		//-- 25 CUSTO 
							 ' ' TRT, 				//-- 26 TRT
							 D1_LOTECTL LOTE 	   	//-- 27 LOTE
							 %Exp:cSelectVe%       	//-- 28 CODITE
							 SD1.R_E_C_N_O_ NRECNO,  //-- 29 RECNO
						     SB1.B1_CONV FATOR,      //-- 30 // Fator conversao 
                             SB1.B1_TIPCONV TIPOCONV,//-- 31 // Tipo conversao   
							 D1_FILIAL               //-- 32 // FILIAL 
							 					 
					FROM %Table:SB1% SB1,%table:SD1% SD1,%table:SF4% SF4
					
					WHERE SB1.B1_COD     =  SD1.D1_COD		AND  	%Exp:cWhereD1C%						
						  SD1.D1_TES     =  SF4.F4_CODIGO	AND
						  SF4.F4_ESTOQUE =  'S'				AND 	SD1.D1_DTDIGIT >= %Exp:MV_PAR05%	AND
						  SD1.D1_DTDIGIT <= %Exp:MV_PAR06%	AND		SD1.D1_ORIGLAN <> 'LF'				   
						  %Exp:cWhereD1%
						  SD1.%NotDel%						AND 	SF4.%NotDel%                           
						  %Exp:cWhereB1A%                   AND
						  %Exp:cWhereB1C%
						  
				    UNION
				    
					SELECT 'SD2',	     			
							SB1.B1_COD,	        	
							SB1.B1_TIPO,		    
							SB1.B1_UM,				
							SB1.B1_GRUPO,		    
							SB1.B1_DESC,		    
							SB1.B1_POSIPI,
							D2_SEQCALC,
							D2_EMISSAO,	//09
							D2_TES,					
							D2_CF,					
							D2_NUMSEQ,				
							D2_DOC,					
							D2_SERIE,				
							D2_QUANT,				
							D2_QTSEGUM,				
							D2_LOCAL,				
							' ',					
							' ',					
							' ',					
							D2_CLIENTE,				
							D2_LOJA,				
							D2_PEDIDO,
							D2_TIPO,				
							%Exp:cSelectD2%			
							' ', 					
							D2_LOTECTL
							%Exp:cSelectVe%
							SD2.R_E_C_N_O_ SD2RECNO,  //-- 29 RECNO
						    SB1.B1_CONV FATOR,        //-- 30 // Fator conversao 
                            SB1.B1_TIPCONV TIPOCONV,  //-- 31 // Tipo conversao 
							D2_FILIAL                 //-- 32 // FILIAL       

							
					FROM %Table:SB1% SB1,%table:SD2% SD2,%table:SF4% SF4
					
					WHERE	SB1.B1_COD     =  SD2.D2_COD		AND	%Exp:cWhereD2C%						
							SD2.D2_TES     =  SF4.F4_CODIGO		AND
							SF4.F4_ESTOQUE =  'S'				AND	SD2.D2_EMISSAO >= %Exp:MV_PAR05%	AND
							SD2.D2_EMISSAO <= %Exp:MV_PAR06%	AND	SD2.D2_ORIGLAN <> 'LF'				   
							%Exp:cWhereD2%
							SD2.%NotDel%						AND SF4.%NotDel%						   
							%Exp:cWhereB1A%                     AND
						  	%Exp:cWhereB1C%
			
					UNION		
				
					SELECT 	'SD3',	    			
							SB1.B1_COD,	    	    
							SB1.B1_TIPO,		    
							SB1.B1_UM,				
							SB1.B1_GRUPO,	     	
							SB1.B1_DESC,		    
							SB1.B1_POSIPI,
							D3_SEQCALC,
							D3_EMISSAO,//09
							D3_TM,					
							D3_CF,					
							D3_NUMSEQ,				
							D3_DOC,					
							' ',					
							D3_QUANT,				
							D3_QTSEGUM,				
							D3_LOCAL,				
							D3_PROJPMS,
							D3_OP,					
							D3_CC,
							' ',					
							' ',					
							' ',					
							' ',									
							%Exp:cSelectD3%			
							D3_TRT, 
							D3_LOTECTL
							%Exp:cSelectVe%
							SD3.R_E_C_N_O_ SD3RECNO, //-- 29 RECNO
							SB1.B1_CONV FATOR,       //-- 30 // Fator conversao 
                            SB1.B1_TIPCONV TIPOCONV, //-- 31 // Tipo conversao 
							D3_FILIAL                //-- 32 // FILIAL      
			
					FROM %Table:SB1% SB1,%table:SD3% SD3
			
					WHERE	SB1.B1_COD     =  SD3.D3_COD 		AND %Exp:cWhereD3C%						
							SD3.D3_EMISSAO >= %Exp:MV_PAR05%	AND	SD3.D3_EMISSAO <= %Exp:MV_PAR06%	AND
							%Exp:cWhereD3% 	
							SD3.%NotDel% 
							
					%Exp:cUnion%			
			
					ORDER BY %Exp:cOrder%
				
				EndSql 
				oSection2:SetParentQuery()
				//===========================================================================
				// Metodo EndQuery ( Classe TRSection )                                    
				//                                                                        
				// Prepara o relatorio para executar o Embedded SQL.                       
				//                                                                         
				// ExpA1 : Array com os parametros do tipo Range                           
				//                                                                         
				//===========================================================================
				oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)
				
				//===========================================================================
				// Inicio da impressao do fluxo do relatorio                               
				//===========================================================================
				DBSelectArea(cAliasTop)
				oReport:SetMeter(nTotRegs)
				
				TCSetField(cAliasTop,DATA ,"D", TamSX3("D1_DTDIGIT")[1], TamSX3("D1_DTDIGIT")[2] )

				While !oReport:Cancel() .And. !(cAliasTop)->(Eof())
					
					If oReport:Cancel()
						Exit
					EndIf
					

					oReport:IncMeter()
					
					//===========================================================================
					// Executa filtro de usuario - SB1					 
					//===========================================================================
					
					If !Empty(cFilUsrSB1) 
						DBSelectArea("SB1")
						SB1->(DBSetOrder(1))
					    SB1->(DBSeek( xFilial("SB1") + (cAliasTop)->PRODUTO))
					    If !(&(cFilUsrSB1))
					       (cAliasTop)->(DBSkip())
			    		   Loop
				    	EndIf   
					EndIf
					
					//oSection1:Cell("FATOR"):SetValue((cAliasTop)->FATOR)       // FATOR DE CONVERSAO 
                    //oSection1:Cell("TIPOCONV"):SetValue((cAliasTop)->TIPOCONV) // TIPO DE CONVERSAO 

					//===========================================================================
					// Executa filtro de usuario - SB2					 
					//===========================================================================
					     
					If !Empty(cFilUsrSB2)
						DBSelectArea("SB2")
						SB2->(DBSetOrder(1))
					    SB2->(DBSeek( xFilial("SB2") + (cAliasTop)->PRODUTO))
					    If !(&(cFilUsrSB2))
					       (cAliasTop)->(DBSkip())
				    	   Loop
				    	EndIf   
					EndIf
					
					//===========================================================================
					// Se nao encontrar no arquivo de saldos ,nao lista 
					//===========================================================================
					DBSelectArea("SB2")
					If !DBSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusFil .Or. lCusEmp,"",MV_PAR08))
						DBSelectArea(cAliasTop)
						DBSkip()
						Loop
					EndIf
					
					DBSelectArea(cAliasTop)
					cProdAnt  := (cAliasTop)->PRODUTO
					cLocalAnt := AllTrim(SB2->B2_LOCAL)
					
					lFirst:=.F.
			
					MR900ImpS1(@aSalAtu,cAliasTop,.T.,lVEIC,lCusFil,lCusEmp,oSection1,oSection2,oReport)
					
					oSection3:Init()
					While !oReport:Cancel() .And. !(cAliasTop)->(Eof()) .And. (cAliasTop)->PRODUTO = cProdAnt .And. If(lCusFil .Or. lCusEmp .Or. lLocProc,.T.,IIf(AllTrim((cAliasTop)->ARQ) <> 'SB1',AllTrim((cAliasTop)->ARMAZEM)==cLocalAnt,.T.))
						oReport:IncMeter()
						lContinua := .F.
						lImpSMov  := .F.
						If AllTrim((cAliasTop)->ARQ) $ "SD1/SD2"
							lFirst:=.T.
							SF4->(DBSeek(xFilial("SF4")+(cAliasTop)->TES))
							//===========================================================================
							// Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  
							//===========================================================================
							// Executa ponto de entrada para verificar se considera TES que 
							// NAO ATUALIZA saldos em estoque.                              
							//===========================================================================
							If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
								lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
								lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
							EndIf
							If SF4->F4_ESTOQUE != "S" .And. !lTesNEst
								DBSkip()
								Loop
							EndIf
						ElseIf AllTrim((cAliasTop)->ARQ) == "SD3"
							lFirst:=.T.
							//===========================================================================
							// Quando movimento ref apropr. indireta, so considera os         
							// movimentos com destino ao almoxarifado de apropriacao indireta.
							//===========================================================================
							lInverteMov:=.F.
							If AllTrim((cAliasTop)->ARMAZEM) != cLocalAnt .Or. lCusFil .Or. lCusEmp
								If !(SubStr((cAliasTop)->CF,3,1) == "3")
									If !(lCusFil .Or. lCusEmp)
										DBSkip()
										Loop
									EndIf
								ElseIf lPriApropri
									lInverteMov:=.T.
								EndIf
							EndIf
							
							//===========================================================================
							// Caso seja uma transferencia de localizacao verifica se lista   
							// o movimento ou nao                                             
							//===========================================================================
							If MV_PAR13 == 2 .And. SubStr((cAliasTop)->CF,3,1) == "4"
								cNumSeqTr := (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM)
								aDadosTran:={(cAliasTOP)->TES,(cAliasTOP)->QUANTIDADE,(cAliasTOP)->CUSTO,(cAliasTOP)->QUANT2UM,(cAliasTOP)->TIPO,;
								(cAliasTOP)->DATA,(cAliasTOP)->CF,(cAliasTOP)->SEQUENCIA,(cAliasTOP)->DOCUMENTO,(cAliasTOP)->PRODUTO,;
								(cAliasTOP)->OP,(cAliasTOP)->PROJETO,(cAliasTOP)->CC,AllTrim((cAliasTOP)->ARQ)}
								DBSkip()
								If (cAliasTOP)->(PRODUTO+SEQUENCIA+ARMAZEM) == cNumSeqTr
									DBSkip()
									Loop
								Else
									lContinua := .T.
									If !Localiza(aDadosTran[10])
										If lFirst
											oSection3:Cell("dDtMov"):SetValue(SToD(aDadosTran[6]))
											oSection3:Cell("cTES"):SetValue(aDadosTran[1])
											oSection3:Cell("cCF"):Show()

											If	lInverteMov
												oSection3:Cell("cCF"):SetValue(SubStr(aDadosTran[7],1,3)+"*")
											Else
												oSection3:Cell("cCF"):SetValue(aDadosTran[7])
											EndIf
											
											If MV_PAR09 $ "Ss"
												oSection3:Cell("cDoc"):SetValue(aDadosTran[8])
											Else
												oSection3:Cell("cDoc"):SetValue(aDadosTran[9])
											EndIf
										EndIf
										
										If aDadosTran[1] <= "500"
											oSection3:Cell("nENTQtd"):Show()
											oSection3:Cell("nENTCus"):Show()
											oSection3:Cell("nCusMov"):Show()
											oSection3:Cell("nENT2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											
											oSection3:Cell("nENTQtd"):SetValue(aDadosTran[2])
											oSection3:Cell("nENTCus"):SetValue(aDadosTran[3])
											oSection3:Cell("nCusMov"):SetValue(aDadosTran[3] / aDadosTran[2])
											
											oSection3:Cell("nENT2UnQtd"):SetValue(aDadosTran[4]) // =======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nSAIQtd"):Hide()
											oSection3:Cell("nSAICus"):Hide()
											oSection3:Cell("nSAI2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nSAIQtd"):SetValue(0)
											oSection3:Cell("nSAICus"):SetValue(0)
											oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											
											aSalAtu[1] += aDadosTran[2]
											aSalAtu[MV_PAR10+1] += aDadosTran[3]
											aSalAtu[7] += aDadosTran[4]
										Else
										
											oSection3:Cell("nENTQtd"):Hide()
											oSection3:Cell("nENTCus"):Hide()
											oSection3:Cell("nENT2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 											
											
											oSection3:Cell("nENTQtd"):SetValue(0)
											oSection3:Cell("nENTCus"):SetValue(0)
											oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 

											
											oSection3:Cell("nCusMov"):Show()
											oSection3:Cell("nSAIQtd"):Show()
											oSection3:Cell("nSAICus"):Show()
											oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nCusMov"):SetValue(aDadosTran[3] / aDadosTran[2])
											oSection3:Cell("nSAIQtd"):SetValue(aDadosTran[2])
											oSection3:Cell("nSAICus"):SetValue(aDadosTran[3])
											
											oSection3:Cell("nSAI2UnQtd"):SetValue(aDadosTran[4])  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											
											aSalAtu[1] -= aDadosTran[2]
											aSalAtu[MV_PAR10+1] -= aDadosTran[3]
											aSalAtu[7] -= aDadosTran[4]
										EndIf
									Else
										lTransEnd := .F.
									EndIf
								EndIf
							EndIf
						EndIf
						If lFirst .And. !lContinua .And. lTransEnd
							oSection3:Cell("dDtMov"):SetValue(SToD(DATA))
							oSection3:Cell("cTES"):SetValue(TES)
							oSection3:Cell("cCF"):Show()
							oSection3:Cell("cCF"):SetValue(CF)
							If	lInverteMov
								oSection3:Cell("cCF"):SetValue(SubStr(CF,1,3)+"*")
							Else
								oSection3:Cell("cCF"):SetValue(CF)
							EndIf
							If MV_PAR09 $ "Ss"
								oSection3:Cell("cDoc"):SetValue(SEQUENCIA)
							Else
								oSection3:Cell("cDoc"):SetValue(DOCUMENTO)
							EndIf
						EndIf
						
						Do Case
							Case AllTrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua .And. lTransEnd
								lDev:=MTR900Dev("SD1",cAliasTop)
								If (cAliasTOP)->TES <= "500" .And. !lDev
									If (cAliasTOP)->TIPONF != "C"
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nCusMov"):Show()
									Else
										oSection3:Cell("nCusMov"):SetValue(0)
										oSection3:Cell("nCusMov"):Hide()
									EndIf
									
									oSection3:Cell("nENTQtd"):Show()
									oSection3:Cell("nENTCus"):Show()
									oSection3:Cell("nENT2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 

									
									oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)
									oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)
	                                oSection3:Cell("nENT2UnQtd"):SetValue((cAliasTOP)->QUANT2UM) // =======================  QTD SEGUNDA UNID MEDIDA 
	                                								
									oSection3:Cell("nSAIQtd"):Hide()
									oSection3:Cell("nSAICus"):Hide()
									oSection3:Cell("nSAI2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 									
									
									oSection3:Cell("nSAIQtd"):SetValue(0)
									oSection3:Cell("nSAICus"):SetValue(0)
									oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
									
									aSalAtu[1] += (cAliasTOP)->QUANTIDADE
									aSalAtu[MV_PAR10+1] += (cAliasTOP)->CUSTO
									aSalAtu[7] += (cAliasTOP)->QUANT2UM
								Else
									If (cAliasTOP)->TIPONF != "C"
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nCusMov"):Show()
									Else
										oSection3:Cell("nCusMov"):SetValue(0)
										oSection3:Cell("nCusMov"):Hide()
									EndIf
									
									oSection3:Cell("nENTQtd"):Hide()
									oSection3:Cell("nENTCus"):Hide()
									oSection3:Cell("nENT2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 
									
									oSection3:Cell("nENTQtd"):SetValue(0)
									oSection3:Cell("nENTCus"):SetValue(0)
									oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
									
									oSection3:Cell("nSAIQtd"):Show()
									oSection3:Cell("nSAICus"):Show()
									oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 

									
									If lDev
										oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE * -1)
										oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO * -1)
                                        oSection3:Cell("nSAI2UnQtd"):SetValue((cAliasTOP)->QUANT2UM * -1)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										aSalAtu[1] += (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1] += (cAliasTOP)->CUSTO
										aSalAtu[7] += (cAliasTOP)->QUANT2UM
									Else
										oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)
										oSection3:Cell("nSAI2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										aSalAtu[1] 			-= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	-= (cAliasTOP)->CUSTO
										aSalAtu[7]			-= (cAliasTOP)->QUANT2UM
									EndIf
								EndIf
							Case AllTrim((cAliasTop)->ARQ) = "SD2" .And. !lContinua .And. lTransEnd
								lDev:=MTR900Dev("SD2",cAliasTop)
								If (cAliasTOP)->TES <= "500" .Or. lDev
									If lDev
										oSection3:Cell("nENTQtd"):Show()
										oSection3:Cell("nENTCus"):Show()
										
										oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE * -1)
										oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO * -1)
										
										oSection3:Cell("nENT2UnQtd"):SetValue((cAliasTOP)->QUANT2UM * -1)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										aSalAtu[1] 			-= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	-= (cAliasTOP)->CUSTO
										aSalAtu[7]			-= (cAliasTOP)->QUANT2UM
									Else
										oSection3:Cell("nENTQtd"):Show()
										oSection3:Cell("nENTCus"):Show()
										
										oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)
										
										oSection3:Cell("nENT2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										aSalAtu[1]			+= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	+= (cAliasTOP)->CUSTO
										aSalAtu[7]			+= (cAliasTOP)->QUANT2UM
									EndIf
									
									If (cAliasTOP)->TIPONF != "C"
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nCusMov"):Show()
									Else
										oSection3:Cell("nCusMov"):SetValue(0)
										oSection3:Cell("nCusMov"):Hide()
									EndIf
									oSection3:Cell("nSAIQtd"):Hide()
									oSection3:Cell("nSAICus"):Hide()
									oSection3:Cell("nSAIQtd"):SetValue(0)
									oSection3:Cell("nSAICus"):SetValue(0)
								Else
									If (cAliasTOP)->TIPONF != "C"
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nCusMov"):Show()
									Else
										oSection3:Cell("nCusMov"):SetValue(0)
										oSection3:Cell("nCusMov"):Hide()
									EndIf

									oSection3:Cell("nENTQtd"):Hide()
									oSection3:Cell("nENTCus"):Hide()
									oSection3:Cell("nENT2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 
									
									oSection3:Cell("nENTQtd"):SetValue(0)
									oSection3:Cell("nENTCus"):SetValue(0)
									oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
									
									oSection3:Cell("nSAIQtd"):Show()
									oSection3:Cell("nSAICus"):Show()
									oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
									
									oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)
									oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)

									oSection3:Cell("nSAI2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)   //=======================  QTD SEGUNDA UNID MEDIDA 
									
									aSalAtu[1]			-= (cAliasTOP)->QUANTIDADE
									aSalAtu[MV_PAR10+1]	-= (cAliasTOP)->CUSTO
									aSalAtu[7]			-= (cAliasTOP)->QUANT2UM
								EndIf
							Case AllTrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua  .And. lTransEnd
								lDev := .F.
								If	lInverteMov
									If (cAliasTOP)->TES > "500"

										oSection3:Cell("nENTQtd"):Show()
										oSection3:Cell("nENTCus"):Show()
										oSection3:Cell("nCusMov"):Show()
										oSection3:Cell("nENT2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										
										oSection3:Cell("nENT2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)  
										
										oSection3:Cell("nSAIQtd"):Hide()
										oSection3:Cell("nSAICus"):Hide()
										oSection3:Cell("nSAI2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nSAIQtd"):SetValue(0)
										oSection3:Cell("nSAICus"):SetValue(0)
										oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										aSalAtu[1]			+= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	+= (cAliasTOP)->CUSTO
										aSalAtu[7]			+= (cAliasTOP)->QUANT2UM
									Else

										oSection3:Cell("nENTQtd"):Hide()
										oSection3:Cell("nENTCus"):Hide()
										oSection3:Cell("nENT2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nENTQtd"):SetValue(0)
										oSection3:Cell("nENTCus"):SetValue(0)
										oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 

										
										oSection3:Cell("nCusMov"):Show()
										oSection3:Cell("nSAIQtd"):Show()
										oSection3:Cell("nSAICus"):Show()
										oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)
										
										oSection3:Cell("nSAI2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)    //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										aSalAtu[1]			-= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	-= (cAliasTOP)->CUSTO
										aSalAtu[7]			-= (cAliasTOP)->QUANT2UM
									EndIf
									If lCusFil .Or. lCusEmp
										lPriApropri:=.F.
									EndIf
								Else
									If (cAliasTOP)->TES <= "500"
									
										oSection3:Cell("nENTQtd"):Show()
										oSection3:Cell("nENTCus"):Show()
										oSection3:Cell("nCusMov"):Show()
										oSection3:Cell("nENT2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 

										oSection3:Cell("nENTQtd"):SetValue((cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nENTCus"):SetValue((cAliasTOP)->CUSTO)
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										
										oSection3:Cell("nENT2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)  
										
										oSection3:Cell("nSAIQtd"):Hide()
										oSection3:Cell("nSAICus"):Hide()
										oSection3:Cell("nSAI2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nSAIQtd"):SetValue(0)
										oSection3:Cell("nSAICus"):SetValue(0)
										oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										aSalAtu[1]			+= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	+= (cAliasTOP)->CUSTO
										aSalAtu[7]			+= (cAliasTOP)->QUANT2UM
									Else

										oSection3:Cell("nENTQtd"):Hide()
										oSection3:Cell("nENTCus"):Hide()
										oSection3:Cell("nENT2UnQtd"):Hide()        //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nENTQtd"):SetValue(0)
										oSection3:Cell("nENTCus"):SetValue(0)
										oSection3:Cell("nENT2UnQtd"):SetValue(0)   //=======================  QTD SEGUNDA UNID MEDIDA 

										
										oSection3:Cell("nCusMov"):Show()
										oSection3:Cell("nSAIQtd"):Show()
										oSection3:Cell("nSAICus"):Show()
										oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nCusMov"):SetValue((cAliasTOP)->CUSTO / (cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nSAIQtd"):SetValue((cAliasTOP)->QUANTIDADE)
										oSection3:Cell("nSAICus"):SetValue((cAliasTOP)->CUSTO)
										
										oSection3:Cell("nSAI2UnQtd"):SetValue((cAliasTOP)->QUANT2UM)    
										
										aSalAtu[1]			-= (cAliasTOP)->QUANTIDADE
										aSalAtu[MV_PAR10+1]	-= (cAliasTOP)->CUSTO
										aSalAtu[7]			-= (cAliasTOP)->QUANT2UM
									EndIf
									If lCusFil .Or. lCusEmp
										lPriApropri:=.T.
									EndIf
								EndIf
						EndCase
						If lFirst  .And. lTransEnd
							oSection3:Cell("nSALDQtd"):SetValue(aSalAtu[1])
							oSection3:Cell("nSALDCus"):SetValue(aSalAtu[MV_PAR10+1])
							oSection3:Cell("nSALD2UnQtd"):SetValue(aSalAtu[7])
						EndIf
						Do Case
							Case AllTrim((cAliasTop)->ARQ) == "SD3" .And. !lContinua  .And. lTransEnd
								If Empty((cAliasTOP)->OP) .And. Empty((cAliasTOP)->PROJETO)
									oSection3:Cell("cCCPVPJOP"):SetValue('CC'+(cAliasTOP)->CC)
								ElseIf !Empty((cAliasTOP)->PROJETO)
									oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+(cAliasTOP)->PROJETO)
								ElseIf !Empty((cAliasTOP)->OP)
									oSection3:Cell("cCCPVPJOP"):SetValue('OP'+(cAliasTOP)->OP)
								EndIf
							Case AllTrim((cAliasTop)->ARQ) == "SD1" .And. !lContinua .And. lTransEnd
								cTipoNf := 'F-'
								SD1->(DBGoTo((cAliasTop)->NRECNO))
								SD2->(DBSetOrder(3))
								If SD2->(DBSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA))
									If SD2->D2_TIPO <> 'B'
										cTipoNf := 'C-'
									EndIf									
								EndIf
								oSection3:Cell("cCCPVPJOP"):SetValue(cTipoNf+(cAliasTOP)->FORNECEDOR)
							Case AllTrim((cAliasTop)->ARQ) == "SD2" .And. !lContinua .And. lTransEnd
								//===========================================================================
								// N - QNC: 002117                                                       
								// Corrigida a ultima coluna do relatorio onde apresentava nas notas     
								// de saida o número do pedido de compra , ao invés de apresentar        
								// o codigo do cliente quando o D2_TIPO="N",                             
								// quando D2_TIPO="B" mostrar o codigo do fornecedor.                    
								//===========================================================================
								If ((cAliasTop)->TIPONF) $ "B|D"
									oSection3:Cell("cCCPVPJOP"):SetValue('F-'+(cAliasTop)->FORNECEDOR)
								Else
									oSection3:Cell("cCCPVPJOP"):SetValue('C-'+(cAliasTop)->FORNECEDOR)
								EndIf
							Case lContinua .And. aDadosTran[14] == "SD3" .And. lTransEnd
								If Empty(aDadosTran[11]) .And. Empty(aDadosTran[12])
									oSection3:Cell("cCCPVPJOP"):SetValue('CC'+aDadosTran[13])
								ElseIf !Empty(aDadosTran[12])
									oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+aDadosTran[12])
								ElseIf !Empty(aDadosTran[11])
									oSection3:Cell("cCCPVPJOP"):SetValue('OP'+aDadosTran[11])
								EndIf
						EndCase
						
						If lFirst .And. lTransEnd
							oSection3:PrintLine()
						EndIf
						lTransEnd := .T.
						
						If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
							If !lContinua //Acerto para utilizar o Array aDadosTranf[]
								DBSkip()
							EndIf
						EndIf
					EndDo
					
					If lFirst
						oReport:PrintText("QTD. NA SEGUNDA UM: "+TransForm(aSalAtu[7],cPicB2Qt2),,oSection3:Cell('nSAICus'):ColPos()) //"QTD. NA SEGUNDA UM: "
					Else
						If !MTR900IsMNT()
							oReport:PrintText("NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO")	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
							oReport:ThinLine()
							lImpSMov := .T.
						Else
							If FindFunction("NGProdMNT")
								aProdsMNT := aClone(NGProdMNT())
								If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
									oReport:PrintText("NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO")	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
									oReport:ThinLine()
									lImpSMov := .T.
								EndIf
							ElseIf SB1->B1_COD <> cProdMNT .And. SB1->B1_COD <> cProdTER
								oReport:PrintText("NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO")	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
								oReport:ThinLine()
								lImpSMov := .T.
							EndIf
						EndIf
					EndIf
					
					oSection1:Finish()
					oSection2:Finish()
					If !lImpSMov
						oSection3:Finish()
					EndIf
				EndDo
				DBSelectArea(cAliasTop)
				Else				
			#EndIf
				DBSelectArea("SD1")
				If MV_PAR11 == 1
					DBSetOrder(5)
				Else
					If lCusFil .Or. lCusEmp
						cIndice:="D1_FILIAL+D1_COD+D1_SEQCALC+D1_NUMSEQ"
					Else
						cIndice:="D1_FILIAL+D1_COD+D1_LOCAL+D1_SEQCALC+D1_NUMSEQ"
					EndIf
					INDREGUA("SD1",cTrbSD1,cIndice,,DBFilter(),"Selecionando Registros")	//"Selecionando Registros"
					nInd := RetIndex("SD1")
					#IFNDEF TOP
			  		   dbSetIndex(cTrbSD1+OrdBagExt())
					#EndIf
					DBSetOrder(nInd+1)
				EndIf
				
				DBSelectArea("SD2")
				If MV_PAR11 == 1
					DBSetOrder(1)
				Else
					If lCusFil .Or. lCusEmp
						cIndice:="D2_FILIAL+D2_COD+D2_SEQCALC+D2_NUMSEQ"
					Else
						cIndice:="D2_FILIAL+D2_COD+D2_LOCAL+D2_SEQCALC+D2_NUMSEQ"
					EndIf
					INDREGUA("SD2",cTrbSD2,cIndice,,,"Selecionando Registros")	//"Selecionando Registros"
					nInd := RetIndex("SD2")
					#IFNDEF TOP
					  dbSetIndex(cTrbSD2+OrdBagExt())
					#EndIf
					DBSetOrder(nInd+1)
				EndIf
				
				DBSelectArea("SD3")
			
				If MV_PAR11 == 1
					DBSetOrder(3)
				Else
					If lCusFil .Or. lCusEmp
						cIndice:="D3_FILIAL+D3_COD+D3_SEQCALC+D3_NUMSEQ"
					Else
						cIndice:="D3_FILIAL+D3_COD+D3_LOCAL+D3_SEQCALC+D3_NUMSEQ"
					EndIf
			
					IndRegua("SD3",cTrbSD3,cIndice,,,"Selecionando Registros")	//"Selecionando Registros"
			
					nInd := RetIndex("SD3")
					#IFNDEF TOP
			     	  dbSetIndex(cTrbSD3+OrdBagExt())
			 		#EndIf
				    DBSetOrder(nInd+1)
				EndIf
				
				DBSelectArea("SB1")
				If ! lVEIC
					If nOrdem == 1
						DBSetOrder(1)
						DBSeek(cFilial+MV_PAR01)
						cOrder := IndexKey()
					ElseIf nOrdem == 2
						DBSetOrder(2)
						DBSeek(cFilial+MV_PAR03)
						cOrder := IndexKey()
					EndIf  
				Else
					If nOrdem == 1
						cOrder := "B1_FILIAL+B1_CODITE"
					ElseIf nOrdem == 2
						cOrder := "B1_FILIAL+B1_TIPO+B1_CODITE"
					EndIf  
				EndIf
				//===========================================================================
				// Transforma parametros Range em expressao Advpl                          
				//===========================================================================
				MakeAdvplExpr(oReport:uParam)
			
				cCondicao := 'B1_FILIAL == "'+xFilial("SB1")+'".And.' 
				cCondicao += 'B1_TIPO >= "'+MV_PAR03+'".And.B1_TIPO <="'+MV_PAR04+'".And.'
				If ! lVEIC
					cCondicao += 'B1_COD >= "'+MV_PAR01+'".And.B1_COD <="'+MV_PAR02+'".And.'
				Else
					cCondicao += 'B1_CODITE >= "'+MV_PAR01+'".And.B1_CODITE <="'+MV_PAR02+'".And.'
				EndIf	
				cCondicao += 'B1_GRUPO >= "'+MV_PAR14+'".And.B1_GRUPO <="'+MV_PAR15+'".And.'	
				cCondicao += 'B1_COD <> "'+SubStr(cProdImp,1,Len(B1_COD))+'"'
			
				oReport:Section(1):SetFilter(cCondicao,cOrder)
				
				DBSelectArea("SB1")
				oReport:SetMeter(nTotRegs)
				
				While !oReport:Cancel() .And. SB1->(!Eof())
					
					If oReport:Cancel()
						Exit
					EndIf
					
					oReport:IncMeter()
					
					DBSelectArea("SB2")
					//===========================================================================
					// Se nao encontrar no arquivo de saldos ,nao lista 
					//===========================================================================
					If !DBSeek(xFilial("SB2")+SB1->B1_COD+If(lCusFil .Or. lCusEmp,"",MV_PAR08))
						DBSelectArea("SB1")
						DBSkip()
						Loop
					EndIf
					
					cProdAnt  := SB1->B1_COD
					cLocalAnt := AllTrim(B2_LOCAL)
					
					DBSelectArea("SD1")
					DBSeek(cFilial+SB1->B1_COD+If(lCusFil .Or. lCusEmp,"",SB2->B2_LOCAL))
					DBSelectArea("SD2")
					DBSeek(cFilial+SB1->B1_COD+If(lCusFil .Or. lCusEmp,"",SB2->B2_LOCAL))
					DBSelectArea("SD3")
					DBSeek(cFilial+SB1->B1_COD+If(lCusFil .Or. lCusEmp.Or.lLocProc,"",SB2->B2_LOCAL))
					
					oSection3:Init()
					While .T.
						lImpSMov := .F.
						lImpS3   := .F.
						DBSelectArea("SD1")
						If !Eof() .And. D1_FILIAL == xFilial("SD1") .And. D1_COD = cProdAnt .And. If(lCusFil .Or. lCusEmp,.T.,AllTrim(D1_LOCAL) = cLocalAnt)
							
							//===========================================================================
							// Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  
							//===========================================================================
							DBSelectArea("SF4")
							DBSeek(xFilial("SF4")+SD1->D1_TES)
							DBSelectArea("SD1")
							//===========================================================================
							// Executa ponto de entrada para verificar se considera TES que 
							// NAO ATUALIZA saldos em estoque.                              
							//===========================================================================
							If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
								lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
								lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
							EndIf
							
							If D1_ORIGLAN $ "LF" .Or. (SF4->F4_ESTOQUE != "S" .And. !lTesNEst)
								DBSkip()
								Loop
							Else
								If D1_DTDIGIT < MV_PAR05 .Or. D1_DTDIGIT > MV_PAR06
									DBSkip()
									Loop
								Else
									cSeqIni := IIf(MV_PAR11==1,D1_NUMSEQ,D1_SEQCALC+D1_NUMSEQ)
									cAlias := Alias()
								EndIf
							EndIf
						EndIf
						
						DBSelectArea("SD2")
						If !Eof() .And. D2_FILIAL == xFilial("SD2") .And. D2_COD = cProdAnt .And. If(lCusFil .Or. lCusEmp,.T.,AllTrim(D2_LOCAL) = cLocalAnt)
							
							DBSelectArea("SF4")
							DBSeek(cFilial+SD2->D2_TES)
							DBSelectArea("SD2")
							
							//===========================================================================
							// Despreza Notas Fiscais Lancadas Pelo Modulo do Livro Fiscal  
							//===========================================================================
							// Executa ponto de entrada para verificar se considera TES que 
							// NAO ATUALIZA saldos em estoque.                              
							//===========================================================================
							If lIxbConTes .And. SF4->F4_ESTOQUE != "S"
								lTesNEst := ExecBlock("MTAAVLTES",.F.,.F.)
								lTesNEst := If(ValType(lTesNEst) # "L",.F.,lTesNEst)
							EndIf
							
							If D2_ORIGLAN == "LF" .Or. (SF4->F4_ESTOQUE != "S" .And. !lTesNEst)
								DBSkip()
								Loop
							Else
								If D2_EMISSAO < MV_PAR05 .Or. D2_EMISSAO > MV_PAR06
									DBSkip()
									Loop
								Else
									If MV_PAR11 == 1
										If D2_NUMSEQ < cSeqIni
											cSeqIni := D2_NUMSEQ
											cAlias  := Alias()
										EndIf
									Else
										If D2_SEQCALC+D2_NUMSEQ < cSeqIni
											cSeqIni := D2_SEQCALC+D2_NUMSEQ
											cAlias  := Alias()
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
						
						DBSelectArea("SD3")
						If !Eof() .And. D3_FILIAL == xFilial("SD3") .And. D3_COD = cProdAnt .And. If(lCusFil .Or. lCusEmp.Or.lLocProc,.T.,AllTrim(D3_LOCAL) = cLocalAnt)
							//===========================================================================
							// Quando movimento ref apropr. indireta, so considera os         
							// movimentos com destino ao almoxarifado de apropriacao indireta.
							//===========================================================================
							lInverteMov:=.F.
							If AllTrim(D3_LOCAL) != cLocalAnt .Or. lCusFil .Or. lCusEmp
								If !(SubStr(D3_CF,3,1) == "3")
									If !(lCusFil .Or. lCusEmp)
										DBSkip()
										Loop
									EndIf
								ElseIf lPriApropri
									lInverteMov:=.T.
								EndIf
							EndIf
							
							If D3_EMISSAO < MV_PAR05 .Or. D3_EMISSAO > MV_PAR06
								DBSkip()
								Loop
							EndIf
							// VALIDACAO TRATAMENTO SE CONSIDERA OS ESTORNO E SE CONSIDERA MOVIMENTOS WMS
							If !D3Valido()
								DBSkip()
								Loop
							EndIf
							
							//===========================================================================
							// Caso seja uma transferencia de localizacao verifica se lista   
							// o movimento ou nao                                             
							//===========================================================================
							If MV_PAR13 == 2 .And. SubStr(D3_CF,3,1) == "4"
								cNumSeqTr := SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL
								nRegTr    := Recno()
								DBSkip()
								If SD3->D3_COD+SD3->D3_NUMSEQ+SD3->D3_LOCAL == cNumSeqTr
									DBSkip()
									Loop
								Else
									DBGoTo(nRegTr)
								EndIf
							EndIf
							If MV_PAR11 == 1
								If D3_NUMSEQ < cSeqIni
									cSeqIni := D3_NUMSEQ
									cAlias  := Alias()
								EndIf
							Else
								If D3_SEQCALC+D3_NUMSEQ < cSeqIni
									cSeqIni := D3_SEQCALC+D3_NUMSEQ
									cAlias  := Alias()
								EndIf
							EndIf
						EndIf
						
						If !Empty(cAlias)
							DBSelectArea(cAlias)
							cCampo1 := Subs(cAlias,2,2)+IIf(cAlias=="SD1","_DTDIGIT","_EMISSAO")
							cCampo2 := Subs(cAlias,2,2)+"_TES"
							cCampo3 := Subs(cAlias,2,2)+"_CF"
							cCampo4 := Subs(cAlias,2,2)+IIf(MV_PAR09 $ "Ss","_NUMSEQ","_DOC" )
							
							If lFirst
								MR900ImpS1(@aSalAtu,,.F.,lVEIC,lCusFil,lCusEmp,oSection1,oSection2,oReport)
								lFirst  := .F.
								lFirst1 := .F.
							EndIf
							
							oSection3:Cell("dDtMov"):SetValue(&cCampo1)
							If cAlias == "SD3"
								oSection3:Cell("cTES"):SetValue(D3_TM)
							Else
								oSection3:Cell("cTES"):SetValue(&cCampo2)
							EndIf
							
							oSection3:Cell("cCF"):Show()
							oSection3:Cell("cCF"):SetValue(&cCampo3)
							oSection3:Cell("cDoc"):SetValue(&cCampo4)
							
							Do Case
								Case cAlias = "SD1"
									lDev:=MTR900Dev("SD1")
									If D1_TES <= "500" .And. !lDev
										If SF1->F1_TIPO != "C"
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10))) / D1_QUANT))
											oSection3:Cell("nCusMov"):Show()
										Else
											oSection3:Cell("nCusMov"):SetValue(0)
											oSection3:Cell("nCusMov"):Hide()
										EndIf
										
										oSection3:Cell("nENTQtd"):Show()
										oSection3:Cell("nENTCus"):Show()
										oSection3:Cell("nENT2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nENTQtd"):SetValue(D1_QUANT)
										oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10))))
										oSection3:Cell("nENT2UnQtd"):SetValue(D1_QTSEGUM)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nSAIQtd"):Hide()
										oSection3:Cell("nSAICus"):Hide()
										oSection3:Cell("nSAI2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nSAIQtd"):SetValue(0)
										oSection3:Cell("nSAICus"):SetValue(0)
										oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 

										
										aSalAtu[1] 			+= D1_QUANT
										aSalAtu[MV_PAR10+1]	+= &(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10)))
										aSalAtu[7]			+= D1_QTSEGUM
									Else
										If SF1->F1_TIPO != "C"
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10))) / D1_QUANT))
											oSection3:Cell("nCusMov"):Show()
										Else
											oSection3:Cell("nCusMov"):SetValue(0)
											oSection3:Cell("nCusMov"):Hide()
										EndIf

										oSection3:Cell("nENTQtd"):Hide()
										oSection3:Cell("nENTCus"):Hide()
										oSection3:Cell("nENT2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nENTQtd"):SetValue(0)
										oSection3:Cell("nENTCus"):SetValue(0)
										oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nSAIQtd"):Show()
										oSection3:Cell("nSAICus"):Show()
										oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										If lDev
											oSection3:Cell("nSAIQtd"):SetValue(D1_QUANT * -1)
											oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10))) * -1)
											oSection3:Cell("nSAI2UnQtd"):SetValue(D1_QTSEGUM * -1)  //=======================  QTD SEGUNDA UNID MEDIDA 

											aSalAtu[1]			+= D1_QUANT
											aSalAtu[MV_PAR10+1]	+= &(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10)))
											aSalAtu[7]			+= D1_QTSEGUM
										Else
											oSection3:Cell("nSAIQtd"):SetValue(D1_QUANT)
											oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10))))
											oSection3:Cell("nSAI2UnQtd"):SetValue(D1_QTSEGUM)  //=======================  QTD SEGUNDA UNID MEDIDA 
			
											aSalAtu[1]			-= D1_QUANT
											aSalAtu[MV_PAR10+1]	-= &(Eval(bBloco,"D1_CUSTO",IIf(MV_PAR10==1," ",MV_PAR10)))
											aSalAtu[7]			-= D1_QTSEGUM
										EndIf
									EndIf
								Case cAlias = "SD2"
									lDev:=MTR900Dev("SD2")
									If D2_TES <= "500" .Or. lDev
										oSection3:Cell("nSAIQtd"):Hide()
										oSection3:Cell("nSAICus"):Hide()
										oSection3:Cell("nSAI2UnQtd"):Hide()       //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nSAIQtd"):SetValue(0)
										oSection3:Cell("nSAICus"):SetValue(0)
										oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 

										
										oSection3:Cell("nENTQtd"):Show()
										oSection3:Cell("nENTCus"):Show()
										oSection3:Cell("nENT2UnQtd"):Show()       //=======================  QTD SEGUNDA UNID MEDIDA 
										
										If lDev
											oSection3:Cell("nENTQtd"):SetValue(D2_QUANT  * -1)
											oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D2_CUSTO",MV_PAR10)) * -1)
											oSection3:Cell("nENT2UnQtd"):SetValue(D2_QTSEGUM  * -1)  //=======================  QTD SEGUNDA UNID MEDIDA    
											
											aSalAtu[1]			-= D2_QUANT
											aSalAtu[MV_PAR10+1]	-= &(Eval(bBloco,"D2_CUSTO",MV_PAR10))
											aSalAtu[7]			-= D2_QTSEGUM
										Else
											oSection3:Cell("nENTQtd"):SetValue(D2_QUANT)
											oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D2_CUSTO",MV_PAR10)))
											oSection3:Cell("nENT2UnQtd"):SetValue(D2_QTSEGUM)  //=======================  QTD SEGUNDA UNID MEDIDA  
											
											aSalAtu[1]			+= D2_QUANT
											aSalAtu[MV_PAR10+1]	+= &(Eval(bBloco,"D2_CUSTO",MV_PAR10))
											aSalAtu[7]			+= D2_QTSEGUM
										EndIf
										If SF2->F2_TIPO != "C"
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D2_CUSTO",MV_PAR10)) / D2_QUANT))
											oSection3:Cell("nCusMov"):Show()
										Else
											oSection3:Cell("nCusMov"):SetValue(0)
											oSection3:Cell("nCusMov"):Hide()
										EndIf
									Else
										oSection3:Cell("nENTQtd"):Hide()
										oSection3:Cell("nENTCus"):Hide()
										oSection3:Cell("nENT2UnQtd"):Hide()       //=======================  QTD SEGUNDA UNID MEDIDA 										
										
										oSection3:Cell("nENTQtd"):SetValue(0)
										oSection3:Cell("nENTCus"):SetValue(0)
										oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
										
										oSection3:Cell("nSAIQtd"):Show()
										oSection3:Cell("nSAICus"):Show()
										oSection3:Cell("nSAI2UnQtd"):Show()       //=======================  QTD SEGUNDA UNID MEDIDA 
										
										If SF2->F2_TIPO != "C"
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D2_CUSTO",MV_PAR10)) / D2_QUANT))
											oSection3:Cell("nCusMov"):Show()
										Else
											oSection3:Cell("nCusMov"):SetValue(0)
											oSection3:Cell("nCusMov"):Hide()
										EndIf
										
										oSection3:Cell("nSAIQtd"):SetValue(D2_QUANT)
										oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D2_CUSTO",MV_PAR10)))
										oSection3:Cell("nSAI2UnQtd"):SetValue(D2_QTSEGUM)      //=======================  QTD SEGUNDA UNID MEDIDA 
			
										aSalAtu[1]			-= D2_QUANT
										aSalAtu[MV_PAR10+1]	-= &(Eval(bBloco,"D2_CUSTO",MV_PAR10))
										aSalAtu[7]			-= D2_QTSEGUM
									EndIf
								OtherWise
									lDev := .F.
									If	lInverteMov
										If D3_TM > "500"
									
											oSection3:Cell("nENTQtd"):Show()
											oSection3:Cell("nENTCus"):Show()
											oSection3:Cell("nCusMov"):Show()
											oSection3:Cell("nENT2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nENTQtd"):SetValue(D3_QUANT)
											oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D3_CUSTO",MV_PAR10)))
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",MV_PAR10)) / D3_QUANT))
											oSection3:Cell("nENT2UnQtd"):SetValue(D3_QTSEGUM)  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nSAIQtd"):Hide()
											oSection3:Cell("nSAICus"):Hide()
											oSection3:Cell("nSAI2UnQtd"):Hide()       //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nSAIQtd"):SetValue(0)
											oSection3:Cell("nSAICus"):SetValue(0)
											oSection3:Cell("nSAI2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											aSalAtu[1]			+= D3_QUANT
											aSalAtu[MV_PAR10+1]	+= &(Eval(bBloco,"D3_CUSTO",MV_PAR10))
											aSalAtu[7]			+= D3_QTSEGUM
										Else
											oSection3:Cell("nENTQtd"):Hide()
											oSection3:Cell("nENTCus"):Hide()
											oSection3:Cell("nENT2UnQtd"):Hide()       //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nENTQtd"):SetValue(0)
											oSection3:Cell("nENTCus"):SetValue(0)
											oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 											
											
											oSection3:Cell("nCusMov"):Show()
											oSection3:Cell("nSAIQtd"):Show()
											oSection3:Cell("nSAICus"):Show()
											oSection3:Cell("nSAI2UnQtd"):Show()       //=======================  QTD SEGUNDA UNID MEDIDA 											
											
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",MV_PAR10)) / D3_QUANT))
											oSection3:Cell("nSAIQtd"):SetValue(D3_QUANT)
											oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D3_CUSTO",MV_PAR10)))
											oSection3:Cell("nSAI2UnQtd"):SetValue(D3_QTSEGUM)      //=======================  QTD SEGUNDA UNID MEDIDA 
											
											aSalAtu[1]			-= D3_QUANT
											aSalAtu[MV_PAR10+1]	-= &(Eval(bBloco,"D3_CUSTO",MV_PAR10))
											aSalAtu[7]			-= D3_QTSEGUM
										EndIf
										If lCusFil .Or. lCusEmp
											lPriApropri:=.F.
										EndIf
									Else
										If D3_TM <= "500"
											oSection3:Cell("nENTQtd"):Show()
											oSection3:Cell("nENTCus"):Show()
											oSection3:Cell("nCusMov"):Show()
											oSection3:Cell("nENT2UnQtd"):Show()                    //=======================  QTD SEGUNDA UNID MEDIDA 											
											
											oSection3:Cell("nENTQtd"):SetValue(D3_QUANT)
											oSection3:Cell("nENTCus"):SetValue(&(Eval(bBloco,"D3_CUSTO",MV_PAR10)))
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",MV_PAR10)) / D3_QUANT))
											oSection3:Cell("nENT2UnQtd"):SetValue(D3_QTSEGUM)      //=======================  QTD SEGUNDA UNID MEDIDA 

											
											oSection3:Cell("nSAIQtd"):Hide()
											oSection3:Cell("nSAICus"):Hide()
											oSection3:Cell("nSAI2UnQtd"):Hide()                    //=======================  QTD SEGUNDA UNID MEDIDA 											
											
											oSection3:Cell("nSAIQtd"):SetValue(0)
											oSection3:Cell("nSAICus"):SetValue(0)
											oSection3:Cell("nSAI2UnQtd"):SetValue(0)               //=======================  QTD SEGUNDA UNID MEDIDA 

											
											aSalAtu[1]			+= D3_QUANT
											aSalAtu[MV_PAR10+1]	+= &(Eval(bBloco,"D3_CUSTO",MV_PAR10))
											aSalAtu[7]			+= D3_QTSEGUM
										Else
											oSection3:Cell("nENTQtd"):Hide()
											oSection3:Cell("nENTCus"):Hide()
											oSection3:Cell("nENT2UnQtd"):Hide()  //=======================  QTD SEGUNDA UNID MEDIDA 											
											
											oSection3:Cell("nENTQtd"):SetValue(0)
											oSection3:Cell("nENTCus"):SetValue(0)
											oSection3:Cell("nENT2UnQtd"):SetValue(0)  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nCusMov"):Show()
											oSection3:Cell("nSAIQtd"):Show()
											oSection3:Cell("nSAICus"):Show()
											oSection3:Cell("nSAI2UnQtd"):Show()  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											oSection3:Cell("nCusMov"):SetValue((&(Eval(bBloco,"D3_CUSTO",MV_PAR10)) / D3_QUANT))
											oSection3:Cell("nSAIQtd"):SetValue(D3_QUANT)
											oSection3:Cell("nSAICus"):SetValue(&(Eval(bBloco,"D3_CUSTO",MV_PAR10)))
											oSection3:Cell("nSAI2UnQtd"):SetValue(D3_QTSEGUM)  //=======================  QTD SEGUNDA UNID MEDIDA 
											
											aSalAtu[1]			-= D3_QUANT
											aSalAtu[MV_PAR10+1]	-= &(Eval(bBloco,"D3_CUSTO",MV_PAR10))
											aSalAtu[7]			-= D3_QTSEGUM
										EndIf
										If lCusFil .Or. lCusEmp
											lPriApropri:=.T.
										EndIf
									EndIf
							EndCase
							
							oSection3:Cell("nSALDQtd"):SetValue(aSalAtu[1])
							oSection3:Cell("nSALDCus"):SetValue(aSalAtu[MV_PAR10+1])
							oSection3:Cell("nSALD2UnQtd"):SetValue(aSalAtu[7])
							
							Do Case
								Case cAlias = "SD3"  && movimentos (SD3)
									If Empty(D3_OP) .And. Empty(D3_PROJPMS)
										oSection3:Cell("cCCPVPJOP"):SetValue('CC'+D3_CC)
									ElseIf !Empty(D3_PROJPMS)
										oSection3:Cell("cCCPVPJOP"):SetValue('PJ'+D3_PROJPMS)
									ElseIf !Empty(D3_OP)
										oSection3:Cell("cCCPVPJOP"):SetValue('OP'+D3_OP)
									EndIf
								Case cAlias = "SD1"  && compras    (SD1)
									cTipoNf := 'F-'
									aAreaSD2:=SD2->(GetArea())
									SD2->(DBSetOrder(3))
									If SD2->(DBSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA))
										If !(SD2->D2_TIPO $ 'B|D')
											cTipoNf := 'C-'
										EndIf									
									EndIf
									FWRestArea(aAreaSD2)
									DBSelectArea('SD1')
									oSection3:Cell("cCCPVPJOP"):SetValue(cTipoNf+D1_FORNECE)
								Case cAlias = "SD2"  && vendas     (SD2)
									If D2_TIPO $ "B|D"
										oSection3:Cell("cCCPVPJOP"):SetValue('F-'+D2_CLIENTE)
									Else
										oSection3:Cell("cCCPVPJOP"):SetValue('C-'+D2_CLIENTE)
									EndIf
							EndCase
				
							cSeqIni := Replicate("z",6)
							cAlias := ""
							
							If !lImpSMov
								oSection3:PrintLine()
							EndIf
							
							If !lInverteMov .Or. (lInverteMov .And. lPriApropri)
								DBSkip()
							EndIf
						Else
							If !lFirst
								oReport:PrintText("QTD. NA SEGUNDA UM: "+AllTrim(TransForm(aSalAtu[7],cPicB2Qt2)),,oSection3:Cell('nSAICus'):ColPos()) //"QTD. NA SEGUNDA UM: "
								lImpS3 := .T.
							Else
								//===========================================================================
								// Verifica se deve ou nao listar os produtos s/movimento 
								//===========================================================================
								If MV_PAR07 == 1
									MR900ImpS1(@aSalAtu,,.F.,lVEIC,lCusFil,lCusEmp,oSection1,oSection2,oReport)
									
									If !MTR900IsMNT()
										oReport:PrintText("NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO")	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
										oReport:ThinLine()
										lImpSMov := .T.
									Else
										If FindFunction("NGProdMNT")
											aProdsMNT := aClone(NGProdMNT())
											If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) == 0
												oReport:PrintText("NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO")	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
												oReport:ThinLine()
												lImpSMov := .T.
											EndIf
										ElseIf SB1->B1_COD <> cProdMNT .And. SB1->B1_COD <> cProdTER
											oReport:PrintText("NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO")	//"NAO HOUVE MOVIMENTACAO PARA ESTE PRODUTO"
											oReport:ThinLine()
											lImpSMov := .T.
										EndIf
									EndIf	
									
								EndIf
							EndIf
							Exit
						EndIf
					EndDo
					lFirst  := .T.
					oSection1:Finish()
					oSection2:Finish()
					If !lImpSMov .And. lImpS3
						oSection3:Finish()
					EndIf
					
					DBSelectArea("SB1")
					DBSkip()
				EndDo
				
				DBSelectArea("SD1")
				If !Empty(cTrbSD1) .And. File(cTrbSD1 + OrdBagExt())
					RetIndex("SD1")
					Ferase(cTrbSD1+OrdBagExt())
				EndIf
				DBSetOrder(1)
				DBSelectArea("SD2")
				If !Empty(cTrbSD2) .And. File(cTrbSD2 + OrdBagExt())
					RetIndex("SD2")
					Ferase(cTrbSD2+OrdBagExt())
				EndIf
				DBSetOrder(1)
				DBSelectArea("SD3")
				If !Empty(cTrbSD3) .And. File(cTrbSD2 + OrdBagExt())
					RetIndex("SD3")
					Ferase(cTrbSD3+OrdBagExt())
				EndIf
				DBSetOrder(1)	
	        #IFDEF TOP
		    	EndIf
			#EndIf

		EndIf
        
        #IFDEF TOP
			If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
		    	If Select(cAliasTop)>0
		    		DBSelectArea(cAliasTop)
		       		DBCloseArea() 
		       	EndIf 
			EndIf
		#EndIf
	Next nForFilial
	
EndIf

// Restaura Filial Corrente
cFilAnt := cFilBack

Return

/*
===============================================================================================================================
Programa----------: MR900ImpS1(aSalAtu,cAliasTop,lQuery,lVEIC,lCusFil,lCusEmp,oSection1,oSection2,oReport)
Autor-------------: Totvs
Data da Criacao---: 25/07/2006                                 .
Descrição---------: ExpA1 = Array com informacoes do saldo inicial do item    
                     [1] = Saldo inicial em quantidade                        
                     [2] = Saldo inicial em valor                             
                     [3] = Saldo inicial na 2a unidade de medida              
                     ExpC1 = Alias                                              
                     ExpL1 = Top                                                
                     ExpL2 = Veiculo                                            
                     ExpL3 = Custo Unificado                                    
                     ExpO1 = Secao 1                                            
                     ExpO2 = Secao 2                                            
                     ExpO3 = obj Report         
Parametros--------: Nenhum                                                           
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MR900ImpS1(aSalAtu,cAliasTop,lQuery,lVEIC,lCusFil,lCusEmp,oSection1,oSection2,oReport)

Local aArea     := FWGetArea()
Local nCusMed   := 0
Local i         := 0
Local nIndice   := 0
Local aSalAlmox := {}
Local cSeek     := ""
Local cFilBkp   := cFilAnt
Local cTrbSB2	:= CriaTrab(,.F.)

Default lQuery   := .F.
Default cAliasTop:="SB1"
Default lCusFil  := .F.
default lCusEmp  := .F.

//============================================================================
// Calcula o Saldo Inicial do Produto             
//============================================================================
If lCusFil
	aArea:=FWGetArea()
	aSalAtu  := { 0,0,0,0,0,0,0 }
	DBSelectArea("SB2")
	DBSetOrder(1)
	DBSeek(cSeek:=xFilial("SB2") + If(lQuery,(cAliasTOP)->PRODUTO,SB1->B1_COD))
	While !Eof() .And. B2_FILIAL+B2_COD == cSeek
		aSalAlmox := CalcEst(If(lQuery,(cAliasTOP)->PRODUTO,SB1->B1_COD),SB2->B2_LOCAL,MV_PAR05,,, ( lCusRep .And. MV_PAR17==2 ) )
		For i:=1 to Len(aSalAtu)
			aSalAtu[i] += aSalAlmox[i]
		Next i
		DBSkip()
	End
	FWRestArea(aArea)
ElseIf lCusEmp
	aArea:=FWGetArea()
	aSalAtu  := { 0,0,0,0,0,0,0 }
	DBSelectArea("SB2")
	DBSetOrder(1)
	INDREGUA("SB2",cTrbSB2,"B2_COD+B2_LOCAL",,,"Selecionando Registros")	//"Selecionando Registros"
	nIndice := RetIndex("SB2") 
	#IFNDEF TOP
	   dbSetIndex(cTrbSB2+OrdBagExt())
	#EndIf
	DBSetOrder(nIndice+1)
	DBSeek(cSeek:=If(lQuery,(cAliasTOP)->PRODUTO,SB1->B1_COD))
	While !Eof() .And. SB2->B2_COD == cSeek
		If !Empty(xFilial("SB2"))
			cFilAnt:=SB2->B2_FILIAL
		EndIf	
		aSalAlmox := CalcEst(If(lQuery,(cAliasTOP)->PRODUTO,SB1->B1_COD),SB2->B2_LOCAL,MV_PAR05,,,( lCusRep .And. MV_PAR17==2 ) )
		For i:=1 to Len(aSalAtu)
			aSalAtu[i] += aSalAlmox[i]
		Next i
		DBSkip()
	End
	DBSelectArea("SB2")
	If !Empty(cTrbSB2) .And. File(cTrbSB2 + OrdBagExt())
		RetIndex("SB2")
		Ferase(cTrbSB2+OrdBagExt())
	EndIf
	cFilAnt := cFilBkp
	FWRestArea(aArea)
Else
	aSalAtu := CalcEst(If(lQuery,(cAliasTOP)->PRODUTO,SB1->B1_COD),MV_PAR08,MV_PAR05,,, ( lCusRep .And. MV_PAR17==2 ) )
EndIf

//============================================================================
// Calcula o Custo de Reposicao do Produto        
//============================================================================
If lCusRep .And. MV_PAR17==2
	aSalAtu := {aSalAtu[1],aSalAtu[18],aSalAtu[19],aSalAtu[20],aSalAtu[21],aSalAtu[22],aSalAtu[07]}
EndIf

//============================================================================
// Calcula o Custo Medio do Produto               
//============================================================================
SB2->(DBSetOrder(1))
SB2->(DBSeek(xFilial("SB2") + If(lQuery,(cAliasTOP)->PRODUTO,SB1->B1_COD)))
If aSalAtu[1] > 0
	nCusmed := aSalAtu[MV_PAR10+1]/aSalAtu[1]
ElseIf aSalAtu[1] == 0 .And. aSalAtu[MV_PAR10+1] == 0
	nCusMed := 0
Else
	nCusmed := &(Eval(bBloco,"SB2->B2_CM",MV_PAR10))
EndIf

oSection1:Init()
oSection2:Init()

oSection1:Cell("nCusMed"):SetValue(nCusMed)
oSection1:Cell("nQtdSal"):SetValue(aSalAtu[1])
oSection1:Cell("nVlrSal"):SetValue(aSalAtu[MV_PAR10+1])			

oSection1:Cell("nQtd2Un"):SetValue(aSalAtu[7])                 // QUANTIDADE NA 2 UNIDADE DE MEDIDA 
oSection1:Cell("FATOR"):SetValue((cAliasTop)->FATOR)       // FATOR DE CONVERSAO 
oSection1:Cell("TIPOCONV"):SetValue((cAliasTop)->TIPOCONV) // TIPO DE CONVERSAO 

#IFDEF TOP
	If !(TcSrvType()=="AS/400") .And. !("POSTGRES" $ TCGetDB())
		oSection1:Cell("cProduto"	):SetValue((cAliasTop)->PRODUTO)			
		oSection1:Cell("cTipo"		):SetValue((cAliasTop)->TIPO	)
		If lVEIC
			oSection2:Cell("cProduto"	):SetValue((cAliasTop)->PRODUTO)			
			oSection2:Cell("cTipo"		):SetValue((cAliasTop)->TIPO	)
		EndIf
		
		DBSelectArea("SB2")
		DBSeek(xFilial("SB2")+(cAliasTop)->PRODUTO+If(lCusFil .Or. lCusEmp,"",MV_PAR08))
 	Else
#EndIf
	oSection1:Cell("cProduto"	):SetValue(SB1->B1_COD)			
	oSection1:Cell("cTipo"		):SetValue(SB1->B1_TIPO)
	If lVEIC
		oSection2:Cell("cProduto"	):SetValue(SB1->B1_COD)			
		oSection2:Cell("cTipo"		):SetValue(SB1->B1_TIPO)
	EndIf
#IFDEF TOP
	EndIf
#EndIf	
oSection1:PrintLine()
oSection2:PrintLine()

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: MTR900VAlm()
Autor-------------: Totvs
Data da Criacao---: 25/07/2006                                 .
Descrição---------: Verifica se ha integração com o modulo SigaMNT/NG
Parametros--------: Nenhum                                                           
Retorno-----------: Nenhum.
===============================================================================================================================
*/
Static Function MTR900IsMNT()
Local aArea
Local aAreaSB1
Local aProdsMNT := {}
Local cProdMNT	 := ""
Local nX := 0
Local lIntegrMNT := .F.

//Esta funcao encontra-se no modulo Manutencao de Ativos (NGUTIL05.PRX), e retorna os produtos (pode ser MAIS de UM), dos parametros de
//Manutencao - "M" (MV_PRODMNT) / Terceiro - "T" (MV_PRODTER) / ou Ambos - "*" ou em branco
If FindFunction("NGProdMNT")
	aProdsMNT := aClone(NGProdMNT("M"))
	If Len(aProdsMNT) > 0
		aArea	 := FWGetArea()
		aAreaSB1 := SB1->(GetArea())
		
		SB1->(DBSelectArea( "SB1" ))
		SB1->(DBSetOrder(1))
		For nX := 1 To Len(aProdsMNT)
			If SB1->(DBSeek( xFilial("SB1") + aProdsMNT[nX] ))
				lIntegrMNT := .T.
				Exit
			EndIf 
		Next nX
		
		FWRestArea(aAreaSB1)
		FWRestArea(aArea)
	EndIf
Else //Se a funcao nao existir, Processa com o parametro aceitando 1 (UM) Produto
	cProdMNT := GetMv("MV_PRODMNT")
	cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
	If !Empty(cProdMNT)
		aArea	 := FWGetArea()
		aAreaSB1 := SB1->(GetArea())
		SB1->(DBSelectArea( "SB1" ))
		SB1->(DBSetOrder(1))
		If SB1->(DBSeek( xFilial('SB1') + cProdMNT ))
			lIntegrMNT := .T.
		EndIf 
		FWRestArea(aAreaSB1)
		FWRestArea(aArea)
	EndIf
EndIf
Return( lIntegrMNT )

/*
===============================================================================================================================
Programa----------: MTR900Dev(cAlias,cAliasTop)
Autor-------------: Totvs
Data da Criacao---: 25/07/2006                                 .
Descrição---------: Avalia se item pertence a uma nota de devolução
Parametros--------: ExpC1 = Alias                                              ³±±
                    ExpC2 = Alias Top                                                     
Retorno-----------: .T. / .F.
===============================================================================================================================
*/
Static Function MTR900Dev(cAlias,cAliasTop)
Static lListaDev := NIL

Local lRet:=.F.
Local cSeek:= If(!Empty(cAliasTop),(cAliasTop)->DOCUMENTO+(cAliasTop)->SERIE+(cAliasTop)->FORNECEDOR+(cAliasTop)->LOJA,"")

// Identifica se lista dev. na mesma coluna
lListaDev := If(ValType(lListaDev)#"L",GetMV("MV_LISTDEV"),lListaDev)

If lListaDev .And. cAlias == "SD1"
	DBSelectArea("SF1")
	If Empty(cSeek)
		cSeek:=SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA
	EndIf
	If DBSeek(xFilial("SF1") + cSeek) .And. SF1->F1_TIPO == "D"
		lRet:=.T.
	EndIf
ElseIf lListaDev .And. cAlias == "SD2"
	DBSelectArea("SF2")
	If Empty(cSeek)
		cSeek:=+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA
	EndIf
	If DBSeek(xFilial("SF2") + cSeek) .And. SF2->F2_TIPO == "D"
		lRet:=.T.
	EndIf
EndIf
DBSelectArea(If(Empty(cAliasTop),cAlias,cAliasTop))
Return lRet
