/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
Julio Paz     |06/03/2025| Chamado 50030. Inclusão de novas informações referentes a centro de custo no relatório.
Igor Melgaço  |01/08/2025| Chamado 51630. Ajustes para performance do relatório.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM011
Autor-------------: Darcio R Sporl
Data da Criacao---: 22/03/2016
Descrição---------: Relatório de pedido completo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM011()

Local oReport   := nil As Object
Private cPerg   := "RCOM011" As Character
Private aOrd    := {"Filial"} As Array
Private aSelFil := {} As Array

If !Pergunte(cPerg,.T.)
   Return
Else
   If MV_PAR01 == 3
      aSelFil := AdmGetFil()
      If Len(aSelFil) < 1
         Return
      EndIf
   EndIf
EndIf

oReport := RCOM011D(cPerg)
oReport:PrintDialog()

U_ITLOGACS( "RCOM011" )

Return

/*
===============================================================================================================================
Programa----------: RCOM011D
Autor-------------: Darcio R Sporl
Data da Criacao---: 22/03/2016
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM011D(cNome As Character)

Local oReport   := Nil As Object
Local oSection1 := Nil As Object
Local oSection2 := Nil As Object

oReport:= TReport():New("RCOM011","Relacao de Pedidos de Compras","RCOM011", {|oReport| RCOM011R(oReport)},"Emissao da Relacao de Pedidos de Compras.")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

If MV_PAR13 == 1
   oSection1:= TRSection():New(oReport, "Pedidos", {"TRBPED"}, , .F., .T.)

   TRCell():New(oSection1,"C7_FILIAL"    ,"TRBPED","Filial"          ,"@!",5)
   TRCell():New(oSection1,"NOMEFIL"      ,"TRBPED","Nome"            ,"@!",30)
   TRCell():New(oSection1,"C7_NUM"       ,"TRBPED","Pedido"          ,"@!",10)  
   TRCell():New(oSection1,"C7_NUMSC"     ,"TRBPED","SC"              ,"@!",10)
   TRCell():New(oSection1,"NOMSC"        ,""      ,"Solicitante"     ,"@!",15)
   TRCell():New(oSection1,"C7_EMISSAO"   ,"TRBPED","Emissao"         ,"@D",10)
   TRCell():New(oSection1,"C7_I_DTFAT"   ,"TRBPED","Dt.Faturamento"  ,"@D",10)
   TRCell():New(oSection1,"C7_DATPRF"    ,"TRBPED","Dt.Entrega"      ,"@D",10)
   TRCell():New(oSection1,"A2_NREDUZ"    ,"TRBPED","Fornecedor"      ,"@!",50)
   TRCell():New(oSection1,"Y1_NOME"      ,"TRBPED","Comprador"       ,"@!",50)
   TRCell():New(oSection1,"C7_I_APLIC"   ,"TRBPED","Aplicacao"       ,"@!",14)
   TRCell():New(oSection1,"ZZI_DESINV"   ,"TRBPED","Investimento"    ,"@!",50)
   TRCell():New(oSection1,"C7_GRUPCOM"   ,"TRBPED","Grupo"           ,"@!",8)
   TRCell():New(oSection1,"C7_I_URGEN"   ,"TRBPED","Urgente"         ,"@!",4)
   TRCell():New(oSection1,"C7_I_CMPDI"   ,"TRBPED","Compra Direta"   ,"@!",4)
   TRCell():New(oSection1,"E4_DESCRI"    ,"TRBPED","Cond. pgto"      ,"@!",50)
   TRCell():New(oSection1,"C7_CC"        ,"TRBPED","Centro de custo" ,"@!",25)
   
   TRCell():New(oSection1,"CONSMSG"   ,"TRBDAD","Obs"            ,"@!",40)
   oSection1:OnPrintLine({|| cNomeFil := TRBPED->C7_FILIAL  + " -  " + AllTrim(FWFilialName(cEmpAnt,TRBPED->C7_FILIAL))  })
   oSection1:SetTotalText({|| "SUBTOTAL FILIAL: " + cNomeFil})   
   
   oSection2:= TRSection():New(oSection1, "Pedidos", {"TRBDAD"}, NIL, .F., .T.)
   TRCell():New(oSection2,"C7_ITEM"      ,"TRBDAD","Item"          ,"@!",8)
   TRCell():New(oSection2,"C7_PRODUTO"   ,"TRBDAD","Produto"       ,"@!",15)
   TRCell():New(oSection2,"B1_DESC"      ,"TRBDAD","Descrição"     ,"@!",50)
   TRCell():New(oSection2,"C7_QUANT"     ,"TRBDAD","Quantidade"    ,"@E 999,999,999",11)
   TRCell():New(oSection2,"C7_QUJE"      ,"TRBDAD","Qtd.Entreg."   ,"@E 999,999,999",11) 
   TRCell():New(oSection2,"C7_PRECO"     ,"TRBDAD","Preço"         ,"@E 999,999,999.999",16)
   TRCell():New(oSection2,"C7_TOTAL"     ,"TRBDAD","Total"         ,"@E 999,999,999.999",16)
   TRCell():New(oSection2,"C7_VLDESC"    ,"TRBDAD","Desconto"      ,"@E 999,999,999.999",16)
   TRCell():New(oSection2,"C7_VALIPI"    ,"TRBDAD","Ipi"           ,"@E 999,999,999.999",16)
   TRCell():New(oSection2,"C7_ICMSRET"   ,"TRBDAD","Icms Ret"      ,"@E 999,999,999.999",16)
   TRCell():New(oSection2,"C7_RESIDUO"   ,"TRBDAD","Residuo"       ,"@!",01)
   TRCell():New(oSection2,"CONSNOTA"     ,"TRBDAD","Notas"         ,"@!",40)
   TRCell():New(oSection2,"C7_CC"        ,"TRBDAD","Centro de custo","@!",25)

   TRFunction():New(oSection2:Cell("C7_QUANT")  ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection2:Cell("C7_PRECO")  ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection2:Cell("C7_TOTAL")  ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection2:Cell("C7_VLDESC") ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection2:Cell("C7_VALIPI") ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection2:Cell("C7_ICMSRET"),NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   oSection2:SetTotalInLine(.F.)

Else
   oSection1:= TRSection():New(oReport, "Pedidos", {"SC7"}, , .F., .T.)
   TRCell():New(oSection1,"C7_FILIAL"     ,"TRBPED","Filial"           ,"@!",5)
   TRCell():New(oSection1,"NOMEFIL"       ,"TRBPED","Nome"             ,"@!",30)
   TRCell():New(oSection1,"C7_NUM"        ,"TRBPED","Pedido"           ,"@!",10)
   TRCell():New(oSection1,"C7_EMISSAO"    ,"TRBPED","Emissao"          ,"@D",10)
   TRCell():New(oSection1,"C7_I_DTFAT"    ,"TRBPED","Dt.Faturamento"   ,"@D",10)
   TRCell():New(oSection1,"C7_DATPRF"     ,"TRBPED","Dt.Entrega"       ,"@D",10)
   TRCell():New(oSection1,"A2_NREDUZ"     ,"TRBPED","Fornecedor"       ,"@!",50)
   TRCell():New(oSection1,"Y1_NOME"       ,"TRBPED","Comprador"        ,"@!",50)
   TRCell():New(oSection1,"C7_I_APLIC"    ,"TRBPED","Aplicacao"        ,"@!",14)
   TRCell():New(oSection1,"ZZI_DESINV"    ,"TRBPED","Investimento"     ,"@!",50)
   TRCell():New(oSection1,"C7_GRUPCOM"    ,"TRBPED","Grupo"            ,"@!",8)
   TRCell():New(oSection1,"C7_I_URGEN"    ,"TRBPED","Urgente"          ,"@!",4)
   TRCell():New(oSection1,"C7_I_CMPDI"    ,"TRBPED","Compra Direta"    ,"@!",4)
   TRCell():New(oSection1,"TOTAL"         ,"TRBDAD","Total"            ,"@E 999,999,999.999",16)
   TRCell():New(oSection1,"VLDESC"        ,"TRBDAD","Desconto"         ,"@E 999,999,999.999",16)
   TRCell():New(oSection1,"VALIPI"        ,"TRBDAD","Ipi"              ,"@E 999,999,999.999",16)
   TRCell():New(oSection1,"ICMSRET"       ,"TRBDAD","Icms Ret"         ,"@E 999,999,999.999",16)
   TRCell():New(oSection1,"CONSNOTA"      ,"TRBDAD","Notas"            ,"@!",40)
   TRCell():New(oSection1,"CONSMSG"       ,"TRBDAD","Obs"              ,"@!",40)
   TRCell():New(oSection1,"E4_DESCRI"     ,"TRBPED","Cond. pgto"       ,"@!",50)
   TRCell():New(oSection1,"C7_CC"         ,"TRBPED","Centro de custo"  ,"@!",25)
   
   TRFunction():New(oSection1:Cell("TOTAL")  ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection1:Cell("VLDESC") ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection1:Cell("VALIPI") ,NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
   TRFunction():New(oSection1:Cell("ICMSRET"),NIL,"SUM",,,"@E 999,999,999.999",,.F.,.T.)
EndIf
   
oReport:SetTotalInLine(.F.)

//=================================
//Aqui, farei uma quebra  por seção
//=================================
oSection1:SetPageBreak(.T.)
oSection1:SetTotalText("TOTAL GERAL ")            

Return(oReport)

/*
===============================================================================================================================
Programa----------: RCOM011R
Autor-------------: Darcio R Sporl
Data da Criacao---: 22/03/2016
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM011R(oReport As Object)
Local oSection1 := oReport:Section(1) As Object
Local oSection2 := oReport:Section(1):Section(1) As Object
Local cQry1 := "" As Character
Local cin := "" As Character
Local nI := 0 As Numeric
Local cFiltro := "" As Character

cFiltro := "WHERE C7_EMISSAO BETWEEN '" + DToS(MV_PAR05) + "' AND '" + DToS(MV_PAR06) + "' "

If MV_PAR01 == 1
   cFiltro += " AND C7_FILIAL <> '  ' "
ElseIf MV_PAR01 == 2
   cFiltro += " AND C7_FILIAL = '" + xFilial("SC7") + "' "
ElseIf MV_PAR01 == 3
   For nI := 1 To Len(aSelFil)
      cIn += "'" + aSelFil[nI] + "',"
   Next nI
   cIn      := SubStr(cIn,1,Len(cIn)-1)
   cFiltro   += " AND C7_FILIAL IN (" + cIn + ") "
EndIf

//=========================================
//Tratamento da clausula where da aplicacao
//=========================================
If MV_PAR02 == 1            //Consumo
   cFiltro += " AND C7_I_APLIC = 'C' "
ElseIf MV_PAR02 == 2         //Investimento
   cFiltro += " AND C7_I_APLIC = 'I' "
ElseIf MV_PAR02 == 3         //Manutenção
   cFiltro += " AND C7_I_APLIC = 'M' "
ElseIf MV_PAR02 == 4         //Serviço
   cFiltro += " AND C7_I_APLIC = 'S' "
EndIf

//=======================
//Filtra grupo de compras
//=======================
If !Empty(MV_PAR03)
   cFiltro += " AND C7_GRUPCOM = '" + MV_PAR03 + "' "
EndIf

//================
//Filtra comprador
//================
If !Empty(MV_PAR04)
   cFiltro += " AND C7_USER = '" + MV_PAR04 + "' "
EndIf

//================
//Filtra Fonecedor
//================
cFiltro += " AND C7_FORNECE BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR09 + "' "
cFiltro += " AND C7_LOJA BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR10 + "' "

//==============
//Filtra urgente
//==============
If MV_PAR11 = 1            //Sim
   cFiltro += " AND C7_I_URGEN = 'S' "
ElseIf MV_PAR11 = 2         //Nao
   cFiltro += " AND C7_I_URGEN = 'N' "
ElseIf MV_PAR11 = 3         //NF
   cFiltro += " AND C7_I_URGEN = 'F' "
EndIf

//==============================================
// Tratamento da clausula where do compra direta
//==============================================
If MV_PAR12 == 1            //Sim
   cFiltro += " AND C7_I_CMPDI = 'S' "
ElseIf MV_PAR12 == 2         //Nao 
   cFiltro += " AND C7_I_CMPDI = 'N' "
EndIf

//==============================================
// Filtro por Posição de Pedidos de Compras
//==============================================
If MV_PAR14 == 2            //Pedidos Atendidos
   cFiltro += " AND C7_QUJE <> 0 "
ElseIf MV_PAR14 == 3         //Pedidos Não Atendidos
    cFiltro += "AND NOT EXISTS (SELECT 'Y' FROM " + RetSqlName("SC7") + " SC7D WHERE SC7D.C7_FILIAL = SC7.C7_FILIAL AND SC7D.C7_NUM = SC7.C7_NUM AND SC7D.C7_QUJE <> 0 AND SC7D.D_E_L_E_T_ = ' ') "
ElseIf MV_PAR14 == 4         //"Parc. Atendidos"
   cFiltro += " AND C7_QUJE > 0 AND C7_QUANT > C7_QUJE "
EndIf

If MV_PAR15 = 1            //Pedidos COM RESIDUOS
   cFiltro += " AND  C7_RESIDUO = 'S'  "
ElseIf MV_PAR15 = 2         //Pedidos SEM RESIDUOS
   cFiltro += " AND  C7_RESIDUO <> 'S'  "
EndIf

cFiltro += "  AND SC7.D_E_L_E_T_ = ' ' "

   If MV_PAR13 == 1    // Relatório Analitico 
      cQry1 := "SELECT  C7_NUM, C7_NUMSC, "
      cQry1 += "        C7_FILIAL, "
      cQry1 += "        M0_FILIAL, "
      cQry1 += "        C7_EMISSAO, "
      cQry1 += "        (SELECT C1_SOLICIT FROM " + RetSqlName("SC1") + " SC1 WHERE C7_FILIAL = C1_FILIAL AND C7_NUM = C1_PEDIDO AND C7_ITEM = C1_ITEMPED AND SC1.D_E_L_E_T_ = ' ' ) NOMSC, "
      cQry1 += "        (SELECT MIN(C7_I_DTFAT) C7_I_DTFAT FROM " + RetSqlName("SC7") + " SC7A WHERE SC7A.C7_FILIAL = SC7.C7_FILIAL AND SC7A.C7_NUM = SC7.C7_NUM AND SC7A.D_E_L_E_T_ = ' ') C7_I_DTFAT, "
      cQry1 += "        (SELECT MIN(C7_DATPRF) C7_DATPRF FROM " + RetSqlName("SC7") + " SC7B WHERE SC7B.C7_FILIAL = SC7.C7_FILIAL AND SC7B.C7_NUM = SC7.C7_NUM AND SC7B.D_E_L_E_T_ = ' ') C7_DATPRF, "
      cQry1 += "        (SELECT LISTAGG(D1_DOC || ' - ' || SubStr(D1_DTDIGIT,7,2) || '/' || SubStr(D1_DTDIGIT,5,2) || '/' || SubStr(D1_DTDIGIT,1,4) , ';') WITHIN GROUP(ORDER BY D1_DOC) COD FROM (SELECT D1_DOC,D1_DTDIGIT FROM " + RetSqlName("SD1") + " SD1 WHERE SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = C7_FILIAL     AND D1_PEDIDO = C7_NUM   AND D1_ITEMPC = C7_ITEM  AND D1_DOC <> ' ' AND rownum <= 20) SD1 ) CONSNOTA, "
      cQry1 += "        C7_I_APLIC, "
      cQry1 += "        C7_I_CDINV, "
      cQry1 += "        ZZI_DESINV, "
      cQry1 += "        C7_I_URGEN, "
      cQry1 += "        C7_I_CMPDI, "
      cQry1 += "        C7_FORNECE, "
      cQry1 += "        C7_LOJA, "
      cQry1 += "        C7_USER,"
      cQry1 += "        C7_GRUPCOM, "
      cQry1 += "        A2_NREDUZ, "
      cQry1 += "        E4_DESCRI, "
      cQry1 += "        Y1_NOME, "
      cQry1 += "        C7_CC, "
      cQry1 += "        C7_TIPO, C7_ITEM, C7_PRODUTO, C7_UM, C7_QUANT, C7_QUJE, C7_PRECO, C7_TOTAL, C7_FORNECE, C7_LOJA, C7_USER, Y1_NOME, C7_RESIDUO, "
      cQry1 += "         C7_I_APLIC, C7_GRUPCOM, C7_I_URGEN, C7_I_CMPDI, B1_DESC, B1_I_DESCD, C7_VLDESC, C7_VALIPI, C7_ICMSRET, "  
      cQry1 += "        C7_OBS "
      cQry1 += "FROM " + RetSqlName("SC7") + " SC7 "
      cQry1 += "JOIN SYS_COMPANY SM0 ON SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = SC7.C7_FILIAL AND SM0.D_E_L_E_T_ = ' ' "
      cQry1 += "JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
      cQry1 += "JOIN " + RetSqlName("SB1") + " SB1 ON B1_FILIAL = '" + xFilial("SB1") + "' AND B1_COD = C7_PRODUTO AND SB1.D_E_L_E_T_ = ' ' "   
      cQry1 += "  LEFT JOIN " + RetSqlName("SY1") + " SY1 ON Y1_FILIAL = '" + xFilial("SY1") + "' AND Y1_USER = C7_USER AND SY1.D_E_L_E_T_ = ' ' "
      cQry1 += "  LEFT JOIN " + RetSqlName("ZZI") + " ZZI ON ZZI_FILIAL = C7_FILIAL AND ZZI_CODINV = C7_I_CDINV AND ZZI.D_E_L_E_T_ = ' ' "
      cQry1 += "  LEFT JOIN " + RetSqlName("SE4") + " SE4 ON E4_FILIAL =  '" + xFilial("SE4") + "' AND E4_CODIGO = C7_COND  AND SE4.D_E_L_E_T_ = ' ' "
      
      cQry1 +=  cFiltro
      
      cQry1 += "ORDER BY C7_FILIAL, C7_NUM, C7_EMISSAO "

      //=================================================================
      //Se o alias estiver aberto, irei fechar, isso ajuda a evitar erros
      //=================================================================
      If Select("TRBPED") <> 0
         DBSelectArea("TRBPED")
         DBCloseArea()
      EndIf

      //=================
      //crio o novo alias
      //=================
      MPSysOpenQuery( cQry1,"TRBPED" )   
      DBSelectArea("TRBPED")
      _nTot := 0
      COUNT TO _nTot
      TRBPED->(DBGoTop())
         
      oReport:SetMeter(_nTot)
       
      _nReg := 0

      cPedAnt := "" //TRBPED->C7_FILIAL + TRBPED->C7_NUM
      //=================================
      //Irei percorrer todos os registros
      //=================================
      While !TRBPED->(Eof())
      
         If oReport:Cancel()
            Exit
         EndIf
         _nReg++

         oReport:IncMeter()
         //===========================
         //inicializo a primeira seção
         //===========================
         oSection1:Init()
            
         If cPedAnt <> (TRBPED->C7_FILIAL + TRBPED->C7_NUM)

            oReport:ThinLine()
            If _nReg > 1
               oSection2:Finish()
            EndIf

            //IncProc("Imprimindo Filial " + AllTrim(TRBPED->C7_FILIAL) + " - " + AllTrim(FWFilialName(cEmpAnt,TRBPED->C7_FILIAL)))

            //========================
            //imprimo a primeira seção
            //========================
            oSection1:Cell("C7_FILIAL"):SetValue(TRBPED->C7_FILIAL)
            oSection1:Cell("NOMEFIL"):SetValue(AllTrim(TRBPED->M0_FILIAL))
            oSection1:Cell("C7_NUM"):SetValue(TRBPED->C7_NUM)
            
            oSection1:Cell("C7_NUMSC"):SetValue(TRBPED->C7_NUMSC)
            oSection1:Cell("NOMSC"):SetValue(TRBPED->NOMSC /*Posicione("SC1",6,TRBPED->C7_FILIAL+TRBPED->C7_NUM,"C1_SOLICIT")*/)
                  
            oSection1:Cell("C7_EMISSAO"):SetValue(SToD(TRBPED->C7_EMISSAO))
            oSection1:Cell("C7_I_DTFAT"):SetValue(SToD(TRBPED->C7_I_DTFAT))
            oSection1:Cell("C7_DATPRF"):SetValue(SToD(TRBPED->C7_DATPRF))
            oSection1:Cell("A2_NREDUZ"):SetValue(TRBPED->A2_NREDUZ)
            oSection1:Cell("Y1_NOME"):SetValue(TRBPED->Y1_NOME)
            oSection1:Cell("C7_I_APLIC"):SetValue(TRBPED->C7_I_APLIC)
            oSection1:Cell("C7_GRUPCOM"):SetValue(TRBPED->C7_GRUPCOM)
            oSection1:Cell("C7_I_URGEN"):SetValue(TRBPED->C7_I_URGEN)
            oSection1:Cell("C7_I_CMPDI"):SetValue(TRBPED->C7_I_CMPDI)
            oSection1:Cell("CONSMSG"):SetValue(TRBPED->C7_OBS /*U_RCOM011O(TRBPED->C7_FILIAL,TRBPED->C7_NUM)*/)
            oSection1:Cell("E4_DESCRI"):SetValue(TRBPED->E4_DESCRI)
            oSection1:Cell("C7_CC"):SetValue(TRBPED->C7_CC) 
            
            oSection1:PrintLine()
            //==========================
            //inicializo a segunda seção
            //==========================
            oSection2:init()
         EndIf

         oSection2:Cell("C7_ITEM"):SetValue(TRBPED->C7_ITEM)
         oSection2:Cell("C7_PRODUTO"):SetValue(TRBPED->C7_PRODUTO)
         oSection2:Cell("B1_DESC"):SetValue(IIf(AllTrim(TRBPED->B1_I_DESCD) $ AllTrim(TRBPED->B1_DESC), AllTrim(TRBPED->B1_DESC), AllTrim(TRBPED->B1_DESC) + " " + AllTrim(TRBPED->B1_I_DESCD)))
         oSection2:Cell("C7_QUANT"):SetValue(TRBPED->C7_QUANT)
         oSection2:Cell("C7_QUJE"):SetValue(TRBPED->C7_QUJE)
         oSection2:Cell("C7_PRECO"):SetValue(TRBPED->C7_PRECO)
         oSection2:Cell("C7_TOTAL"):SetValue(TRBPED->C7_TOTAL)
         oSection2:Cell("C7_VLDESC"):SetValue(TRBPED->C7_VLDESC)
         oSection2:Cell("C7_VALIPI"):SetValue(TRBPED->C7_VALIPI)
         oSection2:Cell("C7_ICMSRET"):SetValue(TRBPED->C7_ICMSRET)
         oSection2:Cell("C7_RESIDUO"):SetValue(TRBPED->C7_RESIDUO)
         oSection2:Cell("C7_CC"):SetValue(TRBPED->C7_CC) 

         oSection2:Cell("CONSNOTA"):SetValue(TRBPED->CONSNOTA)
         oSection2:PrintLine()

         cPedAnt := TRBPED->C7_FILIAL + TRBPED->C7_NUM
         TRBPED->(DBSkip())
      End
      oReport:ThinLine()
      oSection2:Finish()

      oSection1:Finish()
      oSection1:Enable()
      oSection2:Enable()
   Else   // Relatório Sintetico.

      cQry1 := "SELECT  C7_NUM, "
      cQry1 += "        C7_NUMSC, "
      cQry1 += "        C7_FILIAL, "
      cQry1 += "        M0_FILIAL, "
      cQry1 += "        C7_EMISSAO, "
      cQry1 += "        C7_I_APLIC, "
      cQry1 += "        C7_I_CDINV, "
      cQry1 += "        ZZI_DESINV, "
      cQry1 += "        C7_I_URGEN, "
      cQry1 += "        C7_I_CMPDI, "
      cQry1 += "        C7_FORNECE, "
      cQry1 += "        C7_LOJA, "
      cQry1 += "        C7_USER,"
      cQry1 += "        C7_GRUPCOM, "
      cQry1 += "        A2_NREDUZ, "
      cQry1 += "        E4_DESCRI, "
      cQry1 += "        Y1_NOME, "
      cQry1 += "        C7_CC, "
      cQry1 += "        C7_TQUANT , "
      cQry1 += "        C7_TTOTAL , "
      cQry1 += "        C7_TPRECO , "
      cQry1 += "        C7_TVLDESC , "
      cQry1 += "        C7_TVALIPI , "
      cQry1 += "        C7_TICMSRET , "
      cQry1 += "        (SELECT LISTAGG(C1_SOLICIT, ';') WITHIN GROUP( ORDER BY C1_SOLICIT) COD   FROM    (SELECT C1_SOLICIT FROM " + RetSqlName("SC1") + "  SC1      WHERE  SC7.C7_FILIAL = C1_FILIAL  AND SC7.C7_NUM = C1_PEDIDO AND SC1.D_E_L_E_T_ = ' ' AND rownum <= 20 GROUP BY C1_SOLICIT) SC1) NOMSC, "
      cQry1 += "        (SELECT MIN(C7_I_DTFAT) C7_I_DTFAT FROM " + RetSqlName("SC7") + " SC7A WHERE SC7A.C7_FILIAL = SC7.C7_FILIAL AND SC7A.C7_NUM = SC7.C7_NUM AND SC7A.D_E_L_E_T_ = ' ') C7_I_DTFAT, "
      cQry1 += "        (SELECT MIN(C7_DATPRF) C7_DATPRF FROM " + RetSqlName("SC7") + " SC7B WHERE SC7B.C7_FILIAL = SC7.C7_FILIAL AND SC7B.C7_NUM = SC7.C7_NUM AND SC7B.D_E_L_E_T_ = ' ') C7_DATPRF, "
      cQry1 += "        (SELECT LISTAGG(D1_DOC || ' - ' || SubStr(D1_DTDIGIT, 7, 2) || '/' || SubStr(D1_DTDIGIT, 5, 2) || '/' || SubStr(D1_DTDIGIT, 1, 4), ';') WITHIN GROUP( ORDER BY D1_DOC) COD   FROM    (SELECT D1_DOC,D1_DTDIGIT   FROM " + RetSqlName("SD1") + " SD1      WHERE SD1.D_E_L_E_T_ = ' '  AND D1_FILIAL = C7_FILIAL  AND D1_PEDIDO = C7_NUM    AND D1_DOC <> ' ' AND rownum <= 20 GROUP BY D1_DOC,D1_DTDIGIT) SD1) CONSNOTA, "
      cQry1 += "        C7_OBS "
      cQry1 += "FROM ("

      cQry1 += "SELECT C7_NUM, "
      cQry1 += "        C7_NUMSC, "
      cQry1 += "        C7_FILIAL, "
      cQry1 += "        M0_FILIAL, "
      cQry1 += "        C7_EMISSAO, "
      cQry1 += "        C7_I_APLIC, "
      cQry1 += "        C7_I_CDINV, "
      cQry1 += "        ZZI_DESINV, "
      cQry1 += "        C7_I_URGEN, "
      cQry1 += "        C7_I_CMPDI, "
      cQry1 += "        C7_FORNECE, "
      cQry1 += "        C7_LOJA, "
      cQry1 += "        C7_USER, "
      cQry1 += "        C7_GRUPCOM, "
      cQry1 += "        A2_NREDUZ, "
      cQry1 += "        E4_DESCRI, "
      cQry1 += "        Y1_NOME, "
      cQry1 += "        SUM(C7_QUANT) C7_TQUANT, "
      cQry1 += "        SUM(C7_TOTAL) C7_TTOTAL, "
      cQry1 += "        SUM(C7_PRECO) C7_TPRECO, "
      cQry1 += "        SUM(C7_VLDESC) C7_TVLDESC, "
      cQry1 += "        SUM(C7_VALIPI) C7_TVALIPI, "
      cQry1 += "        SUM(C7_ICMSRET) C7_TICMSRET, "
      cQry1 += "        C7_CC, "
      cQry1 += "        MIN(C7_OBS) C7_OBS "
      cQry1 += "FROM " + RetSqlName("SC7") + " SC7 "
      cQry1 += "JOIN SYS_COMPANY SM0 ON SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = SC7.C7_FILIAL AND SM0.D_E_L_E_T_ = ' ' "
      cQry1 += "JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
      cQry1 += "JOIN " + RetSqlName("SB1") + " SB1 ON B1_FILIAL = '" + xFilial("SB1") + "' AND B1_COD = C7_PRODUTO AND SB1.D_E_L_E_T_ = ' ' "   
      cQry1 += "  LEFT JOIN " + RetSqlName("SY1") + " SY1 ON Y1_FILIAL = '" + xFilial("SY1") + "' AND Y1_USER = C7_USER AND SY1.D_E_L_E_T_ = ' ' "
      cQry1 += "  LEFT JOIN " + RetSqlName("ZZI") + " ZZI ON ZZI_FILIAL = C7_FILIAL AND ZZI_CODINV = C7_I_CDINV AND ZZI.D_E_L_E_T_ = ' ' "
      cQry1 += "  LEFT JOIN " + RetSqlName("SE4") + " SE4 ON E4_FILIAL =  '" + xFilial("SE4") + "' AND E4_CODIGO = C7_COND  AND SE4.D_E_L_E_T_ = ' ' "

      cQry1 += cFiltro

      cQry1 += "GROUP BY C7_NUM, "
      cQry1 += "        C7_NUMSC, "
      cQry1 += "        C7_FILIAL, "
      cQry1 += "        M0_FILIAL, "
      cQry1 += "        C7_EMISSAO, "
      cQry1 += "        C7_I_APLIC, "
      cQry1 += "        C7_I_CDINV, "
      cQry1 += "        ZZI_DESINV, "
      cQry1 += "        C7_I_URGEN, "
      cQry1 += "        C7_I_CMPDI, "
      cQry1 += "        C7_FORNECE, "
      cQry1 += "        C7_LOJA, "
      cQry1 += "        C7_USER,"
      cQry1 += "        C7_GRUPCOM, "
      cQry1 += "        A2_NREDUZ, "
      cQry1 += "        E4_DESCRI, "
      cQry1 += "        Y1_NOME, "
      cQry1 += "        C7_CC "
      cQry1 += "ORDER BY C7_FILIAL, C7_NUM, C7_EMISSAO "
      cQry1 += ") SC7 "
      cQry1 += "ORDER BY C7_FILIAL, C7_NUM, C7_EMISSAO "

      //=================================================================
      //Se o alias estiver aberto, irei fechar, isso ajuda a evitar erros
      //=================================================================
      If Select("TRBPED") <> 0
         DBSelectArea("TRBPED")
         DBCloseArea()
      EndIf

      //=================
      //crio o novo alias
      //=================
      MPSysOpenQuery( cQry1,"TRBPED" )
      DBSelectArea("TRBPED")
      _ntot:=0
      COUNT TO _ntot
      TRBPED->(DBGoTop())
         
      oReport:SetMeter(_ntot)
       
       _nReg := 0

      cPedAnt := "" //TRBPED->C7_FILIAL + TRBPED->C7_NUM


      //Irei percorrer todos os meus registros
      While !TRBPED->(Eof())
      
         If oReport:Cancel()
            Exit
         EndIf
      
         //inicializo a primeira seção
         oSection1:Init()
      
         oReport:IncMeter()

         //imprimo a primeira seção
         oSection1:Cell("C7_FILIAL"):SetValue(TRBPED->C7_FILIAL)
         oSection1:Cell("NOMEFIL"):SetValue(AllTrim(TRBPED->M0_FILIAL))
         oSection1:Cell("C7_NUM"):SetValue(TRBPED->C7_NUM)
         oSection1:Cell("C7_EMISSAO"):SetValue(SToD(TRBPED->C7_EMISSAO))
         oSection1:Cell("C7_I_DTFAT"):SetValue(SToD(TRBPED->C7_I_DTFAT))
         oSection1:Cell("C7_DATPRF"):SetValue(SToD(TRBPED->C7_DATPRF))
         oSection1:Cell("A2_NREDUZ"):SetValue(TRBPED->A2_NREDUZ)
         oSection1:Cell("Y1_NOME"):SetValue(TRBPED->Y1_NOME)
         oSection1:Cell("C7_I_APLIC"):SetValue(TRBPED->C7_I_APLIC)
         oSection1:Cell("C7_GRUPCOM"):SetValue(TRBPED->C7_GRUPCOM)
         oSection1:Cell("C7_I_URGEN"):SetValue(TRBPED->C7_I_URGEN)
         oSection1:Cell("C7_I_CMPDI"):SetValue(TRBPED->C7_I_CMPDI)
         oSection1:Cell("TOTAL"):SetValue(TRBPED->C7_TTOTAL)
         oSection1:Cell("VLDESC"):SetValue(TRBPED->C7_TVLDESC)
         oSection1:Cell("VALIPI"):SetValue(TRBPED->C7_TVALIPI)
         oSection1:Cell("ICMSRET"):SetValue(TRBPED->C7_TICMSRET)
         oSection1:Cell("CONSNOTA"):SetValue(TRBPED->CONSNOTA)
         oSection1:Cell("CONSMSG"):SetValue(TRBPED->C7_OBS )
         oSection1:Cell("C7_CC"):SetValue(TRBPED->C7_CC)
         oSection1:PrintLine()
      
         TRBPED->(DBSkip())
      EndDo
      oSection1:Finish()
      oSection1:Enable()
      
   EndIf

Return
