/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |28/11/2025| Chamado 53144. Realizado agrupamento de setor e linha para evitar casos onde o produtor foi alterado
              |          | de um mix para o outro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT078
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2025
Descrição---------: Relatório Base para precificação do Mix - Chamado 52232
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT078

Local oReport := Nil As Object
Pergunte("RGLT078",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2025
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef() As Object

Local oReport := Nil As Object
Local oSection:= Nil As Object
Local _aOrdem := {"Filial","Filial+Setor","Filial+Setor+Linha"} As Array

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT078","Base para precificação do Mix","RGLT078",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta a Composição de preços do Mix, avaliando a ZLF.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//Definicoes da fonte utilizada
oReport:cFontBody := "Arial"
oReport:SetLineHeight(50)
oReport:nFontBody := 8

//Aqui iremos deixar como selecionado a opção Planilha, e iremos habilitar somente o formato de tabela
oReport:SetDevice(4) //Planilha

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZL2_FILIAL","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PROD",/*Table*/,"Produtor"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3"/*Table*/,"Linha"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_VOLUME",/*Tabela*/,"Volume"+CRLF+"Mês Atual", "@E 9,999,999,999" ,13,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_VOLUME",/*Tabela*/,"Volume"+CRLF+"Mês Aterior", "@E 9,999,999,999" ,13,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_VLR_P_LITRO",/*Tabela*/,"Vlr p/Litro"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_VLR_P_LITRO",/*Tabela*/,"Vlr p/Litro"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_TOT_GERAL",/*Tabela*/,"Total Geral"+CRLF+"Mês Atual", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_TOT_GERAL",/*Tabela*/,"Total Geral"+CRLF+"Mês Anterior", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_LLIQSI",/*Tabela*/,"Total Bruto"+CRLF+"p/Litro"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_LLIQSI",/*Tabela*/,"Total Bruto"+CRLF+"p/Litro"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_TOT_LIQ",/*Tabela*/,"Tot Líq."+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_TOT_LIQ",/*Tabela*/,"Tot Líq."+CRLF+"Mês Atnterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_QUALIDADE",/*Tabela*/,"Qualidade"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_QUALIDADE",/*Tabela*/,"Qualidade"+CRLF+"Mês Atnterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_LEITE_COTA",/*Tabela*/,"Leite Cota"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_LEITE_COTA",/*Tabela*/,"Leite Cota"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_GORDURA",/*Tabela*/,"Gordura"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_GORDURA",/*Tabela*/,"Gordura"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_PROTEINA",/*Tabela*/,"Proteína"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_PROTEINA",/*Tabela*/,"Proteína"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_CCS",/*Tabela*/,"CCS"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_CCS",/*Tabela*/,"CCS"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_CBT",/*Tabela*/,"CBT"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_CBT",/*Tabela*/,"CBT"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_DES_GORD",/*Tabela*/,"Des.Gord"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_DES_GORD",/*Tabela*/,"Des.Gord"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_DES_PROT",/*Tabela*/,"Des.Prot"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_DES_PROT",/*Tabela*/,"Des.Prot"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_DES_CCS",/*Tabela*/,"Des.CCS"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_DES_CCS",/*Tabela*/,"Des.CCS"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_DES_CBT",/*Tabela*/,"Des.CBT"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_DES_CBT",/*Tabela*/,"Des.CBT"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_OUTRO_PAG",/*Tabela*/,"Outro Pag"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_OUTRO_PAG",/*Tabela*/,"Outro Pag"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_ADIC_COOPE",/*Tabela*/,"Adic.Coop"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_ADIC_COOPE",/*Tabela*/,"Adic.Coop"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_ADIC_MERDO",/*Tabela*/,"Adic.Merc"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_ADIC_MERDO",/*Tabela*/,"Adic.Merc"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_ADIC_VOLUM",/*Tabela*/,"Adic.Vol"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"o_ADIC_VOLUM",/*Tabela*/,"Adic.Vol"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_BONIF_LTE",/*Tabela*/,"Bonif.Lte"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_BONIF_LTE",/*Tabela*/,"Bonif.Lte"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_BONIF_EXTR",/*Tabela*/,"Bonif.Extr"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_BONIF_EXTR",/*Tabela*/,"Bonif.Extr"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_PGT_MG_CTL",/*Tabela*/,"Pgt.MG CTL"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_PGT_MG_CTL",/*Tabela*/,"Pgt.MG CTL"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_PGT_MG",/*Tabela*/,"Pgt.MG"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_PGT_MG",/*Tabela*/,"Pgt.MG"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_AJ_CUS_VET",/*Tabela*/,"Aj.Cus.Vet."+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_AJ_CUS_VET",/*Tabela*/,"Aj.Cus.Vet."+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_OUT_PG_IMP",/*Tabela*/,"Out.Pg.Imp"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_OUT_PG_IMP",/*Tabela*/,"Out.Pg.Imp"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_INCENT_PRO",/*Tabela*/,"Incent. Prod."+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_INCENT_PRO",/*Tabela*/,"Incent. Prod."+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_DIVERSOS",/*Tabela*/,"Diversos"+CRLF+"Mês Atual", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_DIVERSOS",/*Tabela*/,"Diversos"+CRLF+"Mês Anterior", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_FUNDEPEC",/*Tabela*/,"Fundepec"+CRLF+"Mês Atual", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_FUNDEPEC",/*Tabela*/,"Fundepec"+CRLF+"Mês Anterior", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"N_FUNDESA",/*Tabela*/,"Fundesa"+CRLF+"Mês Atual", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"O_FUNDESA",/*Tabela*/,"Fundesa"+CRLF+"Mês Anterior", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/10/2025
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport As Object,_aOrdem As Array)

Local _cFiltro	:= "%" As Character
Local _cFiltro2	:= "%" As Character
Local _cAlias		:= "" As Character
Local _aSelFil	:= {} As Array
Local _nOrdem		:= oReport:Section(1):GetOrder() As Numeric
Local _cFilial	:= "" As Character
Local _cSetor		:= "" As Character
Local _cLinha		:= "" As Character
Local _nCountRec:= 0 As Numeric

//Chama função que permitirá a seleção das filiais
If MV_PAR03 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZL2")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio  |
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
If _nOrdem == 3
    oQbrLin	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL3_COD") /*uBreak*/, {||"Total da Linha: " + _cLinha} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
    TRFunction():New(oReport:Section(1):Cell("N_VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf
If _nOrdem <> 1
    oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Total do Setor: " + _cSetor } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
    TRFunction():New(oReport:Section(1):Cell("N_VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("N_TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("O_TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("N_VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("N_VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("O_VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("N_TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("O_TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("N_LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("O_LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("N_TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("O_TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)


//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
 oReport:Section(1):Cell("N_DIVERSOS"):SetBlock({||(_cAlias)->(N_BONIF_LTE+N_BONIF_EXTR+N_DIVERSOS) })
 oReport:Section(1):Cell("O_DIVERSOS"):SetBlock({||(_cAlias)->(O_BONIF_LTE+O_BONIF_EXTR+O_DIVERSOS) })

oReport:Section(1):Cell("O_VOLUME"):Disable()
oReport:Section(1):Cell("O_LEITE_COTA"):Disable()
oReport:Section(1):Cell("N_GORDURA"):Disable()
oReport:Section(1):Cell("O_GORDURA"):Disable()
oReport:Section(1):Cell("N_PROTEINA"):Disable()
oReport:Section(1):Cell("O_PROTEINA"):Disable()
oReport:Section(1):Cell("N_CCS"):Disable()
oReport:Section(1):Cell("O_CCS"):Disable()
oReport:Section(1):Cell("N_CBT"):Disable()
oReport:Section(1):Cell("O_CBT"):Disable()
oReport:Section(1):Cell("N_DES_GORD"):Disable()
oReport:Section(1):Cell("O_DES_GORD"):Disable()
oReport:Section(1):Cell("N_DES_PROT"):Disable()
oReport:Section(1):Cell("O_DES_PROT"):Disable()
oReport:Section(1):Cell("N_DES_CCS"):Disable()
oReport:Section(1):Cell("O_DES_CCS"):Disable()
oReport:Section(1):Cell("N_DES_CBT"):Disable()
oReport:Section(1):Cell("O_DES_CBT"):Disable()

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR08) .Or. Empty(MV_PAR08) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro2 += " AND ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR08) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR09)
	_cFiltro2 += " AND ZL3_COD IN " + FormatIn(AllTrim(MV_PAR09),";")
EndIf
_cFiltro += " %"
_cFiltro2 += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
  SELECT ZL2_FILIAL, A2_COD||'-'||A2_LOJA PROD, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI,
        N.VOLUME N_VOLUME,
        O.VOLUME O_VOLUME,
        N.QUALIDADE N_QUALIDADE,
        O.QUALIDADE O_QUALIDADE,
        N.TOT_CRED N_TOT_CRED,
        O.TOT_CRED O_TOT_CRED,
        N.TOT_IMP N_TOT_IMP,
        O.TOT_IMP O_TOT_IMP,
        N.TOT_GERAL N_TOT_GERAL,
        O.TOT_GERAL O_TOT_GERAL,
        N.TOT_DEB N_TOT_DEB,
        O.TOT_DEB O_TOT_DEB,
        N.TOT_DEB2 N_TOT_DEB2,
        O.TOT_DEB2 O_TOT_DEB2,
        N.LEITE_COTA N_LEITE_COTA,
        O.LEITE_COTA O_LEITE_COTA,
        N.GORDURA N_GORDURA,
        O.GORDURA O_GORDURA,
        N.PROTEINA N_PROTEINA,
        O.PROTEINA O_PROTEINA,
        N.CCS N_CCS,
        O.CCS O_CCS,
        N.CBT N_CBT,
        O.CBT O_CBT,
        N.DES_GORD N_DES_GORD,
        O.DES_GORD O_DES_GORD,
        N.DES_PROT N_DES_PROT,
        O.DES_PROT O_DES_PROT,
        N.DES_CCS N_DES_CCS,
        O.DES_CCS O_DES_CCS,
        N.DES_CBT N_DES_CBT,
        O.DES_CBT O_DES_CBT,
        N.OUTRO_PAG N_OUTRO_PAG,
        O.OUTRO_PAG O_OUTRO_PAG,
        N.ADIC_MERDO N_ADIC_MERDO,
        O.ADIC_MERDO O_ADIC_MERDO,
        N.ADIC_VOLUM N_ADIC_VOLUM,
        O.ADIC_VOLUM O_ADIC_VOLUM,
        N.BONIF_LTE N_BONIF_LTE,
        O.BONIF_LTE O_BONIF_LTE,
        N.BONIF_EXTR N_BONIF_EXTR,
        O.BONIF_EXTR O_BONIF_EXTR,
        N.PGT_MG_CTL N_PGT_MG_CTL,
        O.PGT_MG_CTL O_PGT_MG_CTL,
        N.PGT_MG N_PGT_MG,
        O.PGT_MG O_PGT_MG,
        N.AJ_CUS_VET N_AJ_CUS_VET,
        O.AJ_CUS_VET O_AJ_CUS_VET,
        N.OUT_PG_IMP N_OUT_PG_IMP,
        O.OUT_PG_IMP O_OUT_PG_IMP,
        N.ADIC_COOPE N_ADIC_COOPE,
        O.ADIC_COOPE O_ADIC_COOPE,
        ROUND(N.INCENT_PRO / DECODE(N.VOLUME,0,1,N.VOLUME), 4) N_INCENT_PRO,
        ROUND(O.INCENT_PRO / DECODE(O.VOLUME,0,1,O.VOLUME), 4) O_INCENT_PRO,
        N.FUNDEPEC N_FUNDEPEC,
        O.FUNDEPEC O_FUNDEPEC,
        N.FUNDESA N_FUNDESA,
        O.FUNDESA O_FUNDESA,
        N.DIVERSOS N_DIVERSOS,
        O.DIVERSOS O_DIVERSOS,
        ROUND((N.TOT_CRED / DECODE(N.VOLUME,0,1,N.VOLUME)) + (N.TOT_IMP / DECODE(N.VOLUME,0,1,N.VOLUME)) - N.TOT_DEB, 4) N_TOT_LIQ,
        ROUND((O.TOT_CRED / DECODE(O.VOLUME,0,1,O.VOLUME)) + (O.TOT_IMP / DECODE(O.VOLUME,0,1,O.VOLUME)) - O.TOT_DEB, 4) O_TOT_LIQ,
        ROUND(N.TOT_GERAL / DECODE(N.VOLUME,0,1,N.VOLUME), 4) N_VLR_P_LITRO,
        ROUND(O.TOT_GERAL / DECODE(O.VOLUME,0,1,O.VOLUME), 4) O_VLR_P_LITRO,
        ROUND((N.TOT_CRED  - N.TOT_DEB2) / DECODE(N.VOLUME,0,1,N.VOLUME), 4) N_LLIQSI,
        ROUND((O.TOT_CRED  - O.TOT_DEB2) / DECODE(O.VOLUME,0,1,O.VOLUME), 4) O_LLIQSI
    FROM (SELECT ZLF_FILIAL, ZLF_A2COD,ZLF_A2LOJA, /*ZLF_SETOR, ZLF_LINROT,*/
                NVL((SELECT SUM(ZLD_QTDBOM)
                      FROM %Table:ZLD% ZLD
                      WHERE ZLD.D_E_L_E_T_ = ' '
                        AND ZLD_FILIAL = A.ZLF_FILIAL
                        /*AND ZLD_SETOR = A.ZLF_SETOR
                        AND ZLD_LINROT = A.ZLF_LINROT*/
                        AND ZLD_RETIRO = A.ZLF_A2COD
                        AND ZLD_RETILJ = A.ZLF_A2LOJA
                        AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM),0) VOLUME,
                NVL((SELECT SUM(CASE WHEN ZL8_DEBCRE = 'C' AND ZL8_QUALID = 'S' THEN ZLF_VLRLTR
                                  WHEN ZL8_DEBCRE = 'D' AND ZL8_QUALID = 'S' THEN ZLF_VLRLTR * -1 END)
                      FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                      WHERE ZL81.D_E_L_E_T_ = ' '
                        AND ZLF1.D_E_L_E_T_ = ' '
                        AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                        AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                        AND ZLF1.ZLF_FILIAL = A.ZLF_FILIAL
                        AND ZLF1.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF1.ZLF_A2LOJA = A.ZLF_A2LOJA
                        /*AND ZLF1.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF1.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF1.ZLF_CODZLE = ZLE_COD
                        AND ZLF1.ZLF_ENTMIX = 'S'),0) QUALIDADE,
                NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                      FROM %Table:ZLF% ZLF2
                      WHERE ZLF2.D_E_L_E_T_ = ' '
                        AND ZLF2.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF2.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF2.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF2.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF2.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF2.ZLF_CODZLE = ZLE_COD
                        AND ZLF2.ZLF_TP_MIX = 'L'
                        AND ZLF2.ZLF_ENTMIX = 'S'
                        AND ZLF2.ZLF_DEBCRE = 'C'),0) TOT_CRED,
                NVL((SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END)
                      FROM %Table:ZLF% ZLF4, %Table:ZL8% ZL84
                      WHERE ZLF4.D_E_L_E_T_ = ' '
                        AND ZL84.D_E_L_E_T_ = ' '
                        AND ZLF4.ZLF_FILIAL = ZL84.ZL8_FILIAL
                        AND ZLF4.ZLF_EVENTO = ZL84.ZL8_COD
                        AND ZLF4.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF4.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF4.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF4.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF4.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF4.ZLF_CODZLE = ZLE_COD
                        AND ZL84.ZL8_PERTEN = 'P'
                        AND ZL84.ZL8_GRUPO = '000007'),0) TOT_IMP,
                NVL((SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END)
                      FROM %Table:ZLF% ZLF5
                      WHERE ZLF5.D_E_L_E_T_ = ' '
                        AND ZLF5.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF5.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF5.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF5.ZLF_RETIRO = A.ZLF_A2COD
                        AND ZLF5.ZLF_RETILJ = A.ZLF_A2LOJA
                        AND ZLF5.ZLF_CODZLE = ZLE_COD
                        AND ZLF5.ZLF_ENTMIX = 'S'),0) TOT_GERAL,
                NVL((SELECT NVL(SUM(ZLF_VLRLTR), 0)
                      FROM %Table:ZLF% ZLF6
                      WHERE ZLF6.D_E_L_E_T_ = ' '
                        AND ZLF6.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF6.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF6.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF6.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF6.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF6.ZLF_CODZLE = ZLE_COD
                        AND ZLF6.ZLF_DEBCRE = 'D'),0) TOT_DEB,
                  NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                      FROM %Table:ZLF% ZLF2
                      WHERE ZLF2.D_E_L_E_T_ = ' '
                        AND ZLF2.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF2.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF2.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF2.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF2.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF2.ZLF_CODZLE = ZLE_COD
                        AND ZLF2.ZLF_TP_MIX = 'L'
                        AND ZLF2.ZLF_ENTMIX = 'S'
                        AND ZLF2.ZLF_DEBCRE = 'D'),0) TOT_DEB2,
                  NVL((SELECT SUM(ZLF_TOTAL * -1)
                     FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                    WHERE ZL81.D_E_L_E_T_ = ' '
                      AND ZLF1.D_E_L_E_T_ = ' '
                      AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                      AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                      AND ZLF1.ZLF_FILIAL = A.ZLF_FILIAL
                      AND ZLF1.ZLF_A2COD = A.ZLF_A2COD
                      AND ZLF1.ZLF_A2LOJA = A.ZLF_A2LOJA
                      /*AND ZLF1.ZLF_SETOR = A.ZLF_SETOR
                      AND ZLF1.ZLF_LINROT = A.ZLF_LINROT*/
                      AND ZLF1.ZLF_CODZLE = ZLE_COD
                      AND ZL8_NREDUZ = 'FUNDESA'),
                   0) FUNDESA,
               NVL((SELECT SUM(ZLF_TOTAL * -1)
                     FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                    WHERE ZL81.D_E_L_E_T_ = ' '
                      AND ZLF1.D_E_L_E_T_ = ' '
                      AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                      AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                      AND ZLF1.ZLF_FILIAL = A.ZLF_FILIAL
                      AND ZLF1.ZLF_A2COD = A.ZLF_A2COD
                      AND ZLF1.ZLF_A2LOJA = A.ZLF_A2LOJA
                      /*AND ZLF1.ZLF_SETOR = A.ZLF_SETOR
                      AND ZLF1.ZLF_LINROT = A.ZLF_LINROT*/
                      AND ZLF1.ZLF_CODZLE = ZLE_COD
                      AND ZL8_NREDUZ = 'FUNDEPEC'),
                   0) FUNDEPEC,
                               NVL((SELECT SUM(D1_VLINCMG)
                  FROM %Table:SF1% SF1, %Table:SD1% SD1
                WHERE SD1.D_E_L_E_T_ = ' '
                  AND SF1.D_E_L_E_T_ = ' '
                  AND SF1.F1_FILIAL = SD1.D1_FILIAL
                  AND SF1.F1_DOC = SD1.D1_DOC
                  AND SF1.F1_SERIE = SD1.D1_SERIE
                  AND SF1.F1_FORNECE = SD1.D1_FORNECE
                  AND SF1.F1_LOJA = SD1.D1_LOJA
                  AND SF1.F1_FILIAL = A.ZLF_FILIAL
                  AND SF1.F1_FORNECE = A.ZLF_A2COD
                  AND SF1.F1_LOJA = A.ZLF_A2LOJA
                  /*AND SF1.F1_L_SETOR = A.ZLF_SETOR
                  AND SF1.F1_L_LINHA = A.ZLF_LINROT*/
                  AND SF1.F1_L_MIX = ZLE_COD),
               0) INCENT_PRO,
                NVL(LEITE_COTA, 0) LEITE_COTA,
                NVL(GORDURA, 0) GORDURA,
                NVL(PROTEINA, 0) PROTEINA,
                NVL(CCS, 0) CCS,
                NVL(CBT, 0) CBT,
                NVL(DES_GORD, 0) DES_GORD,
                NVL(DES_PROT, 0) DES_PROT,
                NVL(DES_CCS, 0) DES_CCS,
                NVL(DES_CBT, 0) DES_CBT,
                NVL(OUTRO_PAG, 0) OUTRO_PAG,
                NVL(ADIC_MERDO, 0) ADIC_MERDO,
                NVL(ADIC_VOLUM, 0) ADIC_VOLUM,
                NVL(BONIF_LTE, 0) BONIF_LTE,
                NVL(BONIF_EXTR, 0) BONIF_EXTR,
                NVL(PGT_MG_CTL, 0) PGT_MG_CTL,
                NVL(PGT_MG, 0) PGT_MG,
                NVL(AJ_CUS_VET, 0) AJ_CUS_VET,
                NVL(OUT_PG_IMP, 0) OUT_PG_IMP,
                NVL(ADIC_COOPE, 0) ADIC_COOPE,
                NVL(DIVERSOS, 0) DIVERSOS
            FROM (SELECT ZLF_FILIAL, ZLF_A2COD, ZLF_A2LOJA, ZLF_CODZLE, /*ZLF_SETOR, ZLF_LINROT, */
                        Case
                          WHEN ZL8_NREDUZ = 'LEITE COTA' THEN 'LEITE_COTA'
                          WHEN ZL8_NREDUZ = 'GORDURA' THEN 'GORDURA'
                          WHEN ZL8_NREDUZ = 'PROTEINA' THEN 'PROTEINA'
                          WHEN ZL8_NREDUZ = 'CCS' THEN 'CCS'
                          WHEN ZL8_NREDUZ = 'CBT' THEN 'CBT'
                          WHEN ZL8_NREDUZ = 'DES.GORD' THEN 'DES_GORD'
                          WHEN ZL8_NREDUZ = 'DES.PROT' THEN 'DES_PROT'
                          WHEN ZL8_NREDUZ = 'DES.CCS' THEN 'DES_CCS'
                          WHEN ZL8_NREDUZ = 'DES.CBT' THEN 'DES_CBT'
                          WHEN ZL8_NREDUZ = 'OUTRO PAG' THEN 'OUTRO_PAG'
                          WHEN ZL8_NREDUZ = 'ADIC MERDO' THEN 'ADIC_MERDO'
                          WHEN ZL8_NREDUZ = 'ADIC VOLUM' THEN 'ADIC_VOLUM'
                          WHEN ZL8_NREDUZ = 'BONIF.LTE' THEN 'BONIF_LTE'
                          WHEN ZL8_NREDUZ = 'BONIF.EXTR' THEN 'BONIF_EXTR'
                          WHEN ZL8_NREDUZ = 'PGT.MG CTL' THEN 'PGT_MG_CTL'
                          WHEN ZL8_NREDUZ = 'PGT.MG' THEN 'PGT_MG'
                          WHEN ZL8_NREDUZ = 'AJ.CUS.VET' THEN 'AJ_CUS_VET'
                          WHEN ZL8_NREDUZ = 'OUT PG IMP' THEN 'OUT_PG_IMP'
                          WHEN ZL8_NREDUZ = 'ADIC COOPE' THEN 'ADIC_COOPE'
                          Else'DIVERSOS' END EVENTO,
                        ZLF_VLRLTR
                    FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
                  WHERE ZL8.D_E_L_E_T_ = ' '
                    AND ZLF.D_E_L_E_T_ = ' '
                    AND ZLF_FILIAL = ZL8_FILIAL
                    AND ZLF_EVENTO = ZL8_COD
                    %exp:_cFiltro%
                    AND ZLF_CODZLE = %exp:MV_PAR01%
                    AND ZLF_A2COD LIKE 'P%'
                    AND ZLF_A2COD BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
                    AND ZLF_A2LOJA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
                    AND ZLF_ENTMIX = 'S')
          PIVOT(SUM(ZLF_VLRLTR)
            For EVENTO IN('LEITE_COTA' LEITE_COTA,
                          'GORDURA' GORDURA,
                          'PROTEINA' PROTEINA,
                          'CCS' CCS,
                          'CBT' CBT,
                          'DES_GORD' DES_GORD,
                          'DES_PROT' DES_PROT,
                          'DES_CCS' DES_CCS,
                          'DES_CBT' DES_CBT,
                          'OUTRO_PAG' OUTRO_PAG,
                          'ADIC_MERDO' ADIC_MERDO,
                          'ADIC_VOLUM' ADIC_VOLUM,
                          'BONIF_LTE' BONIF_LTE,
                          'BONIF_EXTR' BONIF_EXTR,
                          'PGT_MG_CTL' PGT_MG_CTL,
                          'PGT_MG' PGT_MG,
                          'AJ_CUS_VET' AJ_CUS_VET,
                          'OUT_PG_IMP' OUT_PG_IMP,
                          'ADIC_COOPE' ADIC_COOPE,
                          'DIVERSOS' DIVERSOS)) A, %Table:ZLE% ZLE
          WHERE ZLE.D_E_L_E_T_ = ' '
          AND A.ZLF_CODZLE = ZLE_COD
  ) N, 
  (SELECT ZLF_FILIAL, ZLF_A2COD,ZLF_A2LOJA, /*ZLF_SETOR, ZLF_LINROT,*/
                NVL((SELECT SUM(ZLD_QTDBOM)
                      FROM %Table:ZLD% ZLD
                      WHERE ZLD.D_E_L_E_T_ = ' '
                        AND ZLD_FILIAL = A.ZLF_FILIAL
                        /*AND ZLD_SETOR = A.ZLF_SETOR
                        AND ZLD_LINROT = A.ZLF_LINROT*/
                        AND ZLD_RETIRO = A.ZLF_A2COD
                        AND ZLD_RETILJ = A.ZLF_A2LOJA
                        AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM),0) VOLUME,
                NVL((SELECT SUM(Case WHEN ZL8_DEBCRE = 'C' AND ZL8_QUALID = 'S' THEN ZLF_VLRLTR
                                  WHEN ZL8_DEBCRE = 'D' AND ZL8_QUALID = 'S' THEN ZLF_VLRLTR * -1 END)
                      FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                      WHERE ZL81.D_E_L_E_T_ = ' '
                        AND ZLF1.D_E_L_E_T_ = ' '
                        AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                        AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                        AND ZLF1.ZLF_FILIAL = A.ZLF_FILIAL
                        AND ZLF1.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF1.ZLF_A2LOJA = A.ZLF_A2LOJA
                        /*AND ZLF1.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF1.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF1.ZLF_CODZLE = ZLE_COD
                        AND ZLF1.ZLF_ENTMIX = 'S'),0) QUALIDADE,
                NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                      FROM %Table:ZLF% ZLF2
                      WHERE ZLF2.D_E_L_E_T_ = ' '
                        AND ZLF2.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF2.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF2.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF2.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF2.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF2.ZLF_CODZLE = ZLE_COD
                        AND ZLF2.ZLF_TP_MIX = 'L'
                        AND ZLF2.ZLF_ENTMIX = 'S'
                        AND ZLF2.ZLF_DEBCRE = 'C'),0) TOT_CRED,
                NVL((SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END)
                      FROM %Table:ZLF% ZLF4, %Table:ZL8% ZL84
                      WHERE ZLF4.D_E_L_E_T_ = ' '
                        AND ZL84.D_E_L_E_T_ = ' '
                        AND ZLF4.ZLF_FILIAL = ZL84.ZL8_FILIAL
                        AND ZLF4.ZLF_EVENTO = ZL84.ZL8_COD
                        AND ZLF4.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF4.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF4.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF4.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF4.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF4.ZLF_CODZLE = ZLE_COD
                        AND ZL84.ZL8_PERTEN = 'P'
                        AND ZL84.ZL8_GRUPO = '000007'),0) TOT_IMP,
                NVL((SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END)
                      FROM %Table:ZLF% ZLF5
                      WHERE ZLF5.D_E_L_E_T_ = ' '
                        AND ZLF5.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF5.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF5.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF5.ZLF_RETIRO = A.ZLF_A2COD
                        AND ZLF5.ZLF_RETILJ = A.ZLF_A2LOJA
                        AND ZLF5.ZLF_CODZLE = ZLE_COD
                        AND ZLF5.ZLF_ENTMIX = 'S'),0) TOT_GERAL,
                NVL((SELECT NVL(SUM(ZLF_VLRLTR), 0)
                      FROM %Table:ZLF% ZLF6
                      WHERE ZLF6.D_E_L_E_T_ = ' '
                        AND ZLF6.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF6.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF6.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF6.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF6.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF6.ZLF_CODZLE = ZLE_COD
                        AND ZLF6.ZLF_DEBCRE = 'D'),0) TOT_DEB,
                  NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                      FROM %Table:ZLF% ZLF2
                      WHERE ZLF2.D_E_L_E_T_ = ' '
                        AND ZLF2.ZLF_FILIAL = A.ZLF_FILIAL
                        /*AND ZLF2.ZLF_SETOR = A.ZLF_SETOR
                        AND ZLF2.ZLF_LINROT = A.ZLF_LINROT*/
                        AND ZLF2.ZLF_A2COD = A.ZLF_A2COD
                        AND ZLF2.ZLF_A2LOJA = A.ZLF_A2LOJA
                        AND ZLF2.ZLF_CODZLE = ZLE_COD
                        AND ZLF2.ZLF_TP_MIX = 'L'
                        AND ZLF2.ZLF_ENTMIX = 'S'
                        AND ZLF2.ZLF_DEBCRE = 'D'),0) TOT_DEB2,
                  NVL((SELECT SUM(ZLF_TOTAL * -1)
                     FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                    WHERE ZL81.D_E_L_E_T_ = ' '
                      AND ZLF1.D_E_L_E_T_ = ' '
                      AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                      AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                      AND ZLF1.ZLF_FILIAL = A.ZLF_FILIAL
                      AND ZLF1.ZLF_A2COD = A.ZLF_A2COD
                      AND ZLF1.ZLF_A2LOJA = A.ZLF_A2LOJA
                      /*AND ZLF1.ZLF_SETOR = A.ZLF_SETOR
                      AND ZLF1.ZLF_LINROT = A.ZLF_LINROT*/
                      AND ZLF1.ZLF_CODZLE = ZLE_COD
                      AND ZL8_NREDUZ = 'FUNDESA'),
                   0) FUNDESA,
               NVL((SELECT SUM(ZLF_TOTAL * -1)
                     FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                    WHERE ZL81.D_E_L_E_T_ = ' '
                      AND ZLF1.D_E_L_E_T_ = ' '
                      AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                      AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                      AND ZLF1.ZLF_FILIAL = A.ZLF_FILIAL
                      AND ZLF1.ZLF_A2COD = A.ZLF_A2COD
                      AND ZLF1.ZLF_A2LOJA = A.ZLF_A2LOJA
                      /*AND ZLF1.ZLF_SETOR = A.ZLF_SETOR
                      AND ZLF1.ZLF_LINROT = A.ZLF_LINROT*/
                      AND ZLF1.ZLF_CODZLE = ZLE_COD
                      AND ZL8_NREDUZ = 'FUNDEPEC'),
                   0) FUNDEPEC,
               NVL((SELECT SUM(D1_VLINCMG)
                  FROM %Table:SF1% SF1, %Table:SD1% SD1
                WHERE SD1.D_E_L_E_T_ = ' '
                  AND SF1.D_E_L_E_T_ = ' '
                  AND SF1.F1_FILIAL = SD1.D1_FILIAL
                  AND SF1.F1_DOC = SD1.D1_DOC
                  AND SF1.F1_SERIE = SD1.D1_SERIE
                  AND SF1.F1_FORNECE = SD1.D1_FORNECE
                  AND SF1.F1_LOJA = SD1.D1_LOJA
                  AND SF1.F1_FILIAL = A.ZLF_FILIAL
                  AND SF1.F1_FORNECE = A.ZLF_A2COD
                  AND SF1.F1_LOJA = A.ZLF_A2LOJA
                  /*AND SF1.F1_L_SETOR = A.ZLF_SETOR
                  AND SF1.F1_L_LINHA = A.ZLF_LINROT*/
                  AND SF1.F1_L_MIX = ZLE_COD),
               0) INCENT_PRO,
                NVL(LEITE_COTA, 0) LEITE_COTA,
                NVL(GORDURA, 0) GORDURA,
                NVL(PROTEINA, 0) PROTEINA,
                NVL(CCS, 0) CCS,
                NVL(CBT, 0) CBT,
                NVL(DES_GORD, 0) DES_GORD,
                NVL(DES_PROT, 0) DES_PROT,
                NVL(DES_CCS, 0) DES_CCS,
                NVL(DES_CBT, 0) DES_CBT,
                NVL(OUTRO_PAG, 0) OUTRO_PAG,
                NVL(ADIC_MERDO, 0) ADIC_MERDO,
                NVL(ADIC_VOLUM, 0) ADIC_VOLUM,
                NVL(BONIF_LTE, 0) BONIF_LTE,
                NVL(BONIF_EXTR, 0) BONIF_EXTR,
                NVL(PGT_MG_CTL, 0) PGT_MG_CTL,
                NVL(PGT_MG, 0) PGT_MG,
                NVL(AJ_CUS_VET, 0) AJ_CUS_VET,
                NVL(OUT_PG_IMP, 0) OUT_PG_IMP,
                NVL(ADIC_COOPE, 0) ADIC_COOPE,
                NVL(DIVERSOS, 0) DIVERSOS
            FROM (SELECT ZLF_FILIAL, ZLF_A2COD, ZLF_A2LOJA, ZLF_CODZLE, /*ZLF_SETOR, ZLF_LINROT,*/ 
                        Case
                          WHEN ZL8_NREDUZ = 'LEITE COTA' THEN 'LEITE_COTA'
                          WHEN ZL8_NREDUZ = 'GORDURA' THEN 'GORDURA'
                          WHEN ZL8_NREDUZ = 'PROTEINA' THEN 'PROTEINA'
                          WHEN ZL8_NREDUZ = 'CCS' THEN 'CCS'
                          WHEN ZL8_NREDUZ = 'CBT' THEN 'CBT'
                          WHEN ZL8_NREDUZ = 'DES.GORD' THEN 'DES_GORD'
                          WHEN ZL8_NREDUZ = 'DES.PROT' THEN 'DES_PROT'
                          WHEN ZL8_NREDUZ = 'DES.CCS' THEN 'DES_CCS'
                          WHEN ZL8_NREDUZ = 'DES.CBT' THEN 'DES_CBT'
                          WHEN ZL8_NREDUZ = 'OUTRO PAG' THEN 'OUTRO_PAG'
                          WHEN ZL8_NREDUZ = 'ADIC MERDO' THEN 'ADIC_MERDO'
                          WHEN ZL8_NREDUZ = 'ADIC VOLUM' THEN 'ADIC_VOLUM'
                          WHEN ZL8_NREDUZ = 'BONIF.LTE' THEN 'BONIF_LTE'
                          WHEN ZL8_NREDUZ = 'BONIF.EXTR' THEN 'BONIF_EXTR'
                          WHEN ZL8_NREDUZ = 'PGT.MG CTL' THEN 'PGT_MG_CTL'
                          WHEN ZL8_NREDUZ = 'PGT.MG' THEN 'PGT_MG'
                          WHEN ZL8_NREDUZ = 'AJ.CUS.VET' THEN 'AJ_CUS_VET'
                          WHEN ZL8_NREDUZ = 'OUT PG IMP' THEN 'OUT_PG_IMP'
                          WHEN ZL8_NREDUZ = 'ADIC COOPE' THEN 'ADIC_COOPE'
                          Else'DIVERSOS' END EVENTO,
                        ZLF_VLRLTR
                    FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
                  WHERE ZL8.D_E_L_E_T_ = ' '
                    AND ZLF.D_E_L_E_T_ = ' '
                    AND ZLF_FILIAL = ZL8_FILIAL
                    AND ZLF_EVENTO = ZL8_COD
                    %exp:_cFiltro%
                    AND ZLF_CODZLE = %exp:MV_PAR02%
                    AND ZLF_A2COD LIKE 'P%'
                    AND ZLF_A2COD BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
                    AND ZLF_A2LOJA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
                    AND ZLF_ENTMIX = 'S')
          PIVOT(SUM(ZLF_VLRLTR)
            For EVENTO IN('LEITE_COTA' LEITE_COTA,
                          'GORDURA' GORDURA,
                          'PROTEINA' PROTEINA,
                          'CCS' CCS,
                          'CBT' CBT,
                          'DES_GORD' DES_GORD,
                          'DES_PROT' DES_PROT,
                          'DES_CCS' DES_CCS,
                          'DES_CBT' DES_CBT,
                          'OUTRO_PAG' OUTRO_PAG,
                          'ADIC_MERDO' ADIC_MERDO,
                          'ADIC_VOLUM' ADIC_VOLUM,
                          'BONIF_LTE' BONIF_LTE,
                          'BONIF_EXTR' BONIF_EXTR,
                          'PGT_MG_CTL' PGT_MG_CTL,
                          'PGT_MG' PGT_MG,
                          'AJ_CUS_VET' AJ_CUS_VET,
                          'OUT_PG_IMP' OUT_PG_IMP,
                          'ADIC_COOPE' ADIC_COOPE,
                          'DIVERSOS' DIVERSOS)) A, %Table:ZLE% ZLE
          WHERE ZLE.D_E_L_E_T_ = ' '
          AND A.ZLF_CODZLE = ZLE_COD
  ) O,
  %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:SA2% SA2
          WHERE ZL2.D_E_L_E_T_ = ' '
            AND ZL3.D_E_L_E_T_ = ' '
            AND SA2.D_E_L_E_T_ = ' '
            AND ZL2_FILIAL = N.ZLF_FILIAL
            AND ZL3_FILIAL = N.ZLF_FILIAL
            AND ZL2_COD = ZL3.ZL3_SETOR
            AND ZL3_COD = SA2.A2_L_LI_RO
            AND A2_COD = N.ZLF_A2COD
            AND A2_LOJA = N.ZLF_A2LOJA
            AND A2_COD = O.ZLF_A2COD (+)
            AND A2_LOJA = O.ZLF_A2LOJA (+)
            %exp:_cFiltro2%
  ORDER BY ZL2_FILIAL, ZL2_COD, ZL3_COD, PROD
 EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(1):Init()
Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZL2_FILIAL
	_cSetor	:= (_cAlias)->ZL2_COD + ' - ' + (_cAlias)->ZL2_DESCRI
   _cLinha	:= (_cAlias)->ZL3_COD + ' - ' + (_cAlias)->ZL3_DESCRI
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
