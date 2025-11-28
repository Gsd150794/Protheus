/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |03/07/2025| Chamado 50995.  Inclusão de novas informações/colunas no relatório de conferências fiscais. 
Julio Paz     |07/07/2025| Chamado 50995. Comentar trecho de atualização da tabela temporária de exibição de dados do relatório,
              |          | da linha 860 ate 864.
Igor Melgaço  |13/08/2025| Chamado 49049. Ajustes para melhoria de performance.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS006
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/04/2017
Descrição---------: Relatório de Conferência Fiscal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function RFIS006()

Local oReport  As Object
Local _cTime := "" As Character

Private _aCabecalho:={} As Array
Private _aCampos   :={} As Array
Private _lRet      :=.T. As Logical
Private _aCabList := {} As Array
Private _aCabExcel := {} As Array
Private _aStrucRel := {} As Array


_cSelCFOP:= " SELECT X5_CHAVE ,X5_DESCRI  FROM "+ RetSqlName("SX5") +" X5 WHERE D_E_L_E_T_ = ' ' AND X5_TABELA  = '13' AND X5_FILIAL  = '" + xFilial("SX5") + "' ORDER BY X5_CHAVE"

_aItalac_F3:={}//       1           2         3                   4                      5          6                     7         8          9         10         11        12
//  (_aItalac_F3,{"CPOCAMPO",_cTabela   ,_nCpoChave        , _nCpoDesc               ,_bCondTab   , _cTitAux        , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR07",_cSelCFOP   ,{|Tab|(Tab)->X5_CHAVE },{|Tab| (Tab)->X5_DESCRI},            ,"CFOP"      ,    4     ,          ,          ,.F.        ,       , } )

While .T.

   If !Pergunte("RFIS006")
      Exit
   EndIf
   
   If MV_PAR04 = 1
   
      oReport:=Report()
      oReport:PrintDialog()
      oReport:=NIL
      U_ITLOGACS()
      Loop
   
   Else

      _cTime := Time()

      FWMsgRun( , {|| RFIS006Trab() , _lRet := RFIS006D()}, "Aguarde! Inicio: "+ _cTime , 'Lendo Dados do Relatório...' )
     
      If ! _lRet
         U_ITMsg("Não existem dados para emissão do relatório.","Atenção",,1)
         Loop
      EndIf
      
      FWMsgRun( , {|oproc| _lRet := RFIS006M(,oproc)}, "Aguarde! Inicio: "+ _cTime  , 'Gerando o Relatório...' )
      
   EndIf

EndDo
//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBREL") > 0
   TRBREL->( DBCloseArea() )
EndIf

If Select("TRBRAT") > 0
   TRBRAT->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: Report()
Autor-------------: Alex Wallauer
Data da Criacao---: 18/09/2017
Descrição---------: Relatório de Conferência Fiscal
Parametros--------: Nenhum
Retorno-----------: Objeto
===============================================================================================================================
*/  
Static Function Report()

Local oReport As Object
Local I := 0 As Numeric
Local oSection1 As Object


FWMsgRun( , {|| RFIS006Trab() }, "Aguarde!" , 'Criando Tabelas Temporarias...' )

oReport := TReport():New("RFIS006","Relatório de Conferência Fiscal","RFIS006",{|oReport| RFIS006M(oReport)},"Relatório de Conferência Fiscal")

oSection := TRSection():New(oReport,""	,{""})
oSection:SetTotalInLine(.F.)
oSection1 := TRSection():New(oSection,"RELATORIO DE CONFERENCIA FISCAL"		,{"TRBREL"})
oSection1:SetTotalInLine(.F.)

For I := 1 TO Len(_aCampos)

   SX3->(DBSetOrder(2))
   If SX3->(DBSeek(_aCampos[I]))
      nTam := getsx3cache(_aCampos[I],"X3_TAMANHO")	
      cPict:=AllTrim(getsx3cache(_aCampos[I],"X3_PICTURE"))
      TRCell():New(oSection1,_aCampos[I],"TRBREL",_aCabecalho[I,1],cPict,nTam,/*lPixel*/,/*Block*/	)
   Else
      nTam:=Len(TRBREL->(FIELDGET(FIELDPOS(_aCampos[I]))))
      TRCell():New(oSection1,_aCampos[I],"TRBREL",_aCabecalho[I,1],"@!",nTam,/*lPixel*/,/*Block*/	)
   EndIf

Next
SX3->(DBSetOrder(1))

Return oReport

/*
===============================================================================================================================
Programa----------: RFIS006D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/04/2017
Descrição---------: Gera os dados do relatório e grava em tabelas temporárias para emissão do relatorio em Excel.
Parametros--------: Nenhum
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/  
Static Function RFIS006D() As Logical                                                                                                                  
Local _cWhere := "" As Character
Local _cQry := "" As Character
Local _cOrder := "" As Character
Local _lRet := .T. As Logical

Begin Sequence 

   _cQry := " SELECT FT_FILIAL, "
   _cQry += " ' ' AS ST_NOME, "
   _cQry += " ' ' AS ST_CGC, "
   _cQry += " ' ' AS ST_INSC, "
   _cQry += " ' ' AS ST_INSCM,    "
   _cQry += " ' ' AS ST_CIDCOB, "
   _cQry += " ' ' AS ST__ESTCOB, "
   _cQry += " ' ' AS CCUSTO,   "
   _cQry += " ' ' AS NOME,  "
   _cQry += " ' ' AS CNPJ, "
   _cQry += " ' ' AS INSCREST, "
   _cQry += " ' ' AS NUNICIPIO,   "
   _cQry += " ' ' AS ESTADO, "
   _cQry += " ' ' AS ARMAZEM,"
   _cQry += " ' ' AS UNIMEDIDA,"
   _cQry += " ' ' AS A2_NOME,"
   _cQry += " ' ' AS A2_MUN,"
   _cQry += " ' ' AS A2_EST,"
   _cQry += " FT_EMISSAO,"
   _cQry += " FT_ENTRADA,"
   _cQry += " FT_NFISCAL,"
   _cQry += " FT_SERIE,"
   _cQry += " FT_ESPECIE,"
   _cQry += " FT_CHVNFE,"
   _cQry += " FT_TIPOMOV,"
   _cQry += " FT_TIPO,"
   _cQry += " FT_CFOP,"
   _cQry += " FT_NFORI,"
   _cQry += " FT_SERORI,"
   _cQry += " FT_OBSERV,"
   _cQry += " FT_CLIEFOR,"
   _cQry += " FT_LOJA,"
   _cQry += " FT_PRODUTO,"
   _cQry += " FT_ITEM,"
   _cQry += " FT_POSIPI,"
   _cQry += " FT_QUANT,"
   _cQry += " FT_PRCUNIT,"
   _cQry += " FT_DESCONT,"
   _cQry += " FT_DESPESA,"
   _cQry += " FT_FRETE,"
   _cQry += " FT_SEGURO,"
   _cQry += " FT_TOTAL,"
   _cQry += " FT_VALCONT,"
   _cQry += " FT_CLASFIS,"
   _cQry += " FT_BASEICM,"
   _cQry += " FT_ALIQICM,"
   _cQry += " FT_VALICM,"
   _cQry += " FT_BASERET,"
   _cQry += " FT_ALIQSOL,"
   _cQry += " FT_MARGEM,"
   _cQry += " FT_ICMSRET,"
   _cQry += " FT_BASEDES,"
   _cQry += " FT_ICMSCOM,"
   _cQry += " FT_CTIPI,"
   _cQry += " FT_BASEIPI,"
   _cQry += " FT_ALIQIPI,"
   _cQry += " FT_VALIPI,"
   _cQry += " FT_CSTPIS,"
   _cQry += " FT_BASEPIS,"
   _cQry += " FT_ALIQPIS,"
   _cQry += " FT_VALPIS,"
   _cQry += " FT_CSTCOF,"
   _cQry += " FT_BASECOF,"
   _cQry += " FT_ALIQCOF,"
   _cQry += " FT_VALCOF,"
   _cQry += " FT_VALIRR,"
   _cQry += " FT_VALINS,"
   _cQry += " FT_VRETCSL,"
   _cQry += " FT_VRETPIS,"
   _cQry += " FT_VRETCOF,"
   _cQry += " D1_VALISS,"
   _cQry += " FT_VALFUM,"
   _cQry += " FT_VLSENAR,"
   _cQry += " FT_VALFUND,"
   _cQry += " FT_VALANTI,"
   _cQry += " FT_DTCANC,"
   _cQry += " SF2_DEV,"
   _cQry += " F1_FILIAL,"
   _cQry += " F1_FORNECE,"
   _cQry += " F1_LOJA,"
   _cQry += " F1_SERIE,"
   _cQry += " F1_DOC,"
   _cQry += " D1_TES,"
   _cQry += " D1_BASEIPI,"
   _cQry += " D1_IPI,"
   _cQry += " D1_VALIPI,"
   _cQry += " D1_DESPESA,"
   _cQry += " D1_VALFRE,"
   _cQry += " D1_SEGURO,"
   _cQry += " D1_VUNIT,"
   _cQry += " D1_CC,"
   _cQry += " D1_LOCAL,"
   _cQry += " D1_UM,"
   _cQry += " D1_BASEISS,"
   _cQry += " D1_ALIQISS,"
   _cQry += " SF1_DESC01,"
   _cQry += " SF1_VALISS,"
   _cQry += " SF1_DUPLIC,"
   _cQry += " SF1_ESTOQUE,"
   _cQry += " SF1_FINALID,"
   _cQry += " SF1_A2_NOME,"
   _cQry += " SF1_A2_INSCR,"
   _cQry += " SF1_A2_IM,"
   _cQry += " SF1_A2_MUN,"
   _cQry += " SF1_A2_EST,"
   _cQry += " SF1_A2_CGC,"
   _cQry += " SF1_A2_CALCIRF,"
   _cQry += " SF1_A1_NOME,"
   _cQry += " SF1_A1_INSCR,"
   _cQry += " SF1_A1_MUN,"
   _cQry += " SF1_A1_EST,"
   _cQry += " SF1_A1_CGC,"
   _cQry += " SF1_A1_SIMPNAC,"
   _cQry += " F1_TIPO,"
   _cQry += " SF1_DEV,"
   _cQry += " F2_I_CTRA,"
   _cQry += " F2_I_LTRA,"
   _cQry += " F2_I_PLACA,"
   _cQry += " F2_I_FRET,"
   _cQry += " F2_TPFRETE,"
   _cQry += " D2_BASEIPI,"
   _cQry += " D2_IPI,"
   _cQry += " D2_VALIPI,"
   _cQry += " D2_DESPESA,"
   _cQry += " D2_VALFRE,"
   _cQry += " D2_SEGURO,"
   _cQry += " D2_PRUNIT,"
   _cQry += " D2_TES,"
   _cQry += " D2_CCUSTO,"
   _cQry += " SF2_DESC01,"
   _cQry += " D2_LOCAL,"
   _cQry += " D2_UM,"
   _cQry += " D2_BASEISS,"
   _cQry += " D2_ALIQISS,"
   _cQry += " D2_VALISS,"
   _cQry += " SF2_DUPLIC,"
   _cQry += " SF2_ESTOQUE,"
   _cQry += " SF2_FINALID,"
   _cQry += " SF2_A1_NOME,"
   _cQry += " SF2_A1_INSCR,"
   _cQry += " SF2_A1_MUN,"
   _cQry += " SF2_A1_EST,"
   _cQry += " SF2_A1_CGC,"
   _cQry += " SF2_A1_SIMPNAC,"
   _cQry += " SF2_A2_NOME,"
   _cQry += " SF2_A2_INSCR,"
   _cQry += " SF2_A2_INSCM,"
   _cQry += " SF2_A2_MUN,"
   _cQry += " SF2_A2_EST,"
   _cQry += " SF2_A2_CGC,"
   _cQry += " SF2_A2_CALCIRF,"
   _cQry += " SF2T_A2_NOME,"
   _cQry += " SF2T_A2_MUN,"
   _cQry += " SF2T_A2_EST,"
   _cQry += " F2_TIPO,"
   _cQry += " C7_OBSMREC,"
   _cQry += " M0_CODIGO,"
   _cQry += " M0_CODFIL,"
   _cQry += " M0_CGC,"
   _cQry += " M0_NOME,"
   _cQry += " M0_INSCR,"
   _cQry += " M0_INSCRM,"
   _cQry += " M0_MUN,"
   _cQry += " M0_EST,"
   _cQry += " B1_DESC,"
   _cQry += " B1_GRUPO,"
   _cQry += " BM_DESC,"
   _cQry += " C7_NUM,"
   _cQry += " F3_CODRSEF, "
   _cQry += " QTD_ITENS, "
   _cQry += " D1_FILIAL, "
   _cQry += " D1_PEDIDO, "
   _cQry += " D1_FORNECE, "
   _cQry += " D1_LOJA, "
   _cQry += " D1_ITEMPC, " 
   _cQry += " ED_CODIGO,"
   _cQry += " ED_DESCRIC "

   _cQry += " FROM "
   _cQry += "( "

   _cQry += " SELECT FT_FILIAL, "
   _cQry += "  FT_EMISSAO,		"
   _cQry += "  FT_ENTRADA,		"
   _cQry += "  FT_NFISCAL,		"
   _cQry += "  FT_SERIE,		"
   _cQry += "  FT_ESPECIE,		"
   _cQry += "  FT_CHVNFE,		"
   _cQry += "  SF3.F3_CODRSEF,		"
   _cQry += "  FT_TIPOMOV,		"
   _cQry += "  FT_TIPO,		"
   _cQry += "  D1_TES,		"
   _cQry += "  FT_CFOP,		"
   _cQry += "  FT_NFORI,		"
   _cQry += "  FT_SERORI,		"
   _cQry += "  FT_OBSERV,		"
   _cQry += "  FT_CLIEFOR,		"
   _cQry += "  FT_LOJA,		"
   _cQry += "  FT_PRODUTO,		"
   _cQry += "  FT_ITEM,		"
   _cQry += "  FT_POSIPI,		"
   _cQry += "  FT_QUANT,		"
   _cQry += "  FT_PRCUNIT,		"
   _cQry += "  FT_DESCONT,		"
   _cQry += "  FT_DESPESA,		"
   _cQry += "  FT_FRETE,		"
   _cQry += "  FT_SEGURO,		"
   _cQry += "  FT_TOTAL,		"
   _cQry += "  FT_VALCONT,		"
   _cQry += "  FT_CLASFIS,		"
   _cQry += "  FT_BASEICM,		"
   _cQry += "  FT_ALIQICM,		"
   _cQry += "  FT_VALICM,		"
   _cQry += "  FT_BASERET,		"
   _cQry += "  FT_ALIQSOL,		"
   _cQry += "  FT_MARGEM,		"
   _cQry += "  FT_ICMSRET,		"
   _cQry += "  FT_BASEDES,		"
   _cQry += "  FT_ICMSCOM,		"
   _cQry += "  FT_CTIPI,		"
   _cQry += "  FT_BASEIPI,		"
   _cQry += "  FT_ALIQIPI,		"
   _cQry += "  FT_VALIPI,		"
   _cQry += "  FT_CSTPIS,		"
   _cQry += "  FT_BASEPIS,		"
   _cQry += "  FT_ALIQPIS,		"
   _cQry += "  FT_VALPIS,		"
   _cQry += "  FT_CSTCOF,		"
   _cQry += "  FT_BASECOF,		"
   _cQry += "  FT_ALIQCOF,		"
   _cQry += "  FT_VALCOF,		"
   _cQry += "  FT_VALIRR,		"
   _cQry += "  FT_VALINS,		"
   _cQry += "  FT_VRETCSL,		"
   _cQry += "  FT_VRETPIS,		"
   _cQry += "  FT_VRETCOF,		"
   _cQry += "  0 AS D1_VALISS,		"
   _cQry += "  FT_VALFUM,		"
   _cQry += "  FT_VLSENAR,		"
   _cQry += "  FT_VALFUND,		"
   _cQry += "  FT_VALANTI,		"
   _cQry += "  FT_DTCANC,"
   _cQry += "  F1_FILIAL, "
   _cQry += "  F1_FORNECE, "
   _cQry += "  F1_LOJA, "
   _cQry += "  F1_SERIE, "
   _cQry += "  F1_DOC, "
   _cQry += "  SF1.D1_BASEIPI , "
   _cQry += "  SF1.D1_IPI, "
   _cQry += "  SF1.D1_VALIPI, "
   _cQry += "  SF1.D1_DESPESA, "
   _cQry += "  SF1.D1_VALFRE, "
   _cQry += "  SF1.D1_SEGURO, "
   _cQry += "  SF1.D1_VUNIT, "
   _cQry += "  SF1.D1_CC, "
   _cQry += "  SF1.CTT_DESC01 AS SF1_DESC01, "
   _cQry += "  SF1.D1_LOCAL, "
   _cQry += "  SF1.D1_UM, "
   _cQry += "  SF1.D1_BASEISS, "
   _cQry += "  SF1.D1_ALIQISS, "
   _cQry += "  SF1.D1_VALISS AS SF1_VALISS, "
   _cQry += "  SF1.F4_DUPLIC AS SF1_DUPLIC, "
   _cQry += "  SF1.F4_ESTOQUE AS SF1_ESTOQUE, "
   _cQry += "  SF1.F4_FINALID AS SF1_FINALID,"
   _cQry += "  SF1.SF1_A2_NOME, "
   _cQry += "  SF1.SF1_A2_INSCR,  "
   _cQry += "  SF1.SF1_A2_IM, "
   _cQry += "  SF1.SF1_A2_MUN, "
   _cQry += "  SF1.SF1_A2_EST,  "
   _cQry += "  SF1.SF1_A2_CGC, "
   _cQry += "  SF1.SF1_A2_CALCIRF, "
   _cQry += "  SF1.SF1_A1_NOME, "
   _cQry += "  SF1.SF1_A1_INSCR,  "
   _cQry += "  SF1.SF1_A1_MUN, "
   _cQry += "  SF1.SF1_A1_EST, "
   _cQry += "  SF1.SF1_A1_CGC, "
   _cQry += "  SF1.SF1_A1_SIMPNAC, "
   _cQry += "  SF1.F1_TIPO, "
   _cQry += "  (Case WHEN SF1.F1_TIPO  IN ('D','B') THEN 'DEV' Else ' ' END) AS SF1_DEV, "

   _cQry += "  ED_CODIGO, "
   _cQry += "  ED_DESCRIC, "

   _cQry += "  F2_I_CTRA,		"
   _cQry += "  F2_I_LTRA,		"
   _cQry += "  F2_I_PLACA,		"
   _cQry += "  F2_I_FRET,		"
   _cQry += "  F2_TPFRETE,		"
   _cQry += "  SF2.D2_BASEIPI, "
   _cQry += "  SF2.D2_IPI, "
   _cQry += "  SF2.D2_VALIPI, "
   _cQry += "  SF2.D2_DESPESA, "
   _cQry += "  SF2.D2_VALFRE, "
   _cQry += "  SF2.D2_SEGURO, "
   _cQry += "  SF2.D2_PRUNIT, "
   _cQry += "  SF2.D2_TES, "
   _cQry += "  SF2.D2_CCUSTO, "
   _cQry += "  SF2.CTT_DESC01 AS SF2_DESC01, "
   _cQry += "  SF2.D2_LOCAL, "
   _cQry += "  SF2.D2_UM, "
   _cQry += "  SF2.D2_BASEISS, "
   _cQry += "  SF2.D2_ALIQISS, "
   _cQry += "  SF2.D2_VALISS, "
   _cQry += "  SF2.F4_DUPLIC AS SF2_DUPLIC, "
   _cQry += "  SF2.F4_ESTOQUE AS SF2_ESTOQUE, "
   _cQry += "  SF2.F4_FINALID AS SF2_FINALID, "
   _cQry += "  SF2.SF2_A1_NOME, "
   _cQry += "  SF2.SF2_A1_INSCR,  "
   _cQry += "  SF2.SF2_A1_MUN, "
   _cQry += "  SF2.SF2_A1_EST, "
   _cQry += "  SF2.SF2_A1_CGC, "
   _cQry += "  SF2.SF2_A1_SIMPNAC, "
   _cQry += "  SF2.SF2_A2_NOME, "
   _cQry += "  SF2.SF2_A2_INSCR,  "
   _cQry += "  SF2.SF2_A2_INSCM, "
   _cQry += "  SF2.SF2_A2_MUN, "
   _cQry += "  SF2.SF2_A2_EST,  "
   _cQry += "  SF2.SF2_A2_CGC, "
   _cQry += "  SF2.SF2_A2_CALCIRF, "
   _cQry += "  SF2.SF2T_A2_NOME, "
   _cQry += "  SF2.SF2T_A2_MUN, "
   _cQry += "  SF2.SF2T_A2_EST,  "
   _cQry += "  SF2.F2_TIPO, "
   _cQry += "  (Case WHEN SF2.F2_TIPO  IN ('D','B') THEN 'DEV' Else ' ' END) AS SF2_DEV ,"
   _cQry += "  M0_CODIGO, "
   _cQry += "  M0_CODFIL, "
   _cQry += "  M0_CGC, "
   _cQry += "  M0_NOME, "
   _cQry += "  M0_INSCR, "
   _cQry += "  M0_INSCRM, "
   _cQry += "  M0_MUN, "
   _cQry += "  M0_EST, "
   _cQry += "  B1_DESC,		"
   _cQry += "  B1_GRUPO,	"
   _cQry += "  BM_DESC,		"
   _cQry += "  SD2_2.QTD_ITENS, "
   _cQry += "  SD1_2.D1_FILIAL,  "
   _cQry += "  SD1_2.D1_PEDIDO,  "
   _cQry += "  SD1_2.D1_FORNECE ,"
   _cQry += "  SD1_2.D1_LOJA,    "
   _cQry += "  SD1_2.D1_ITEMPC,  "
   _cQry += "  Case WHEN SFT.FT_TIPOMOV = 'E' THEN C7_NUM Else ' ' END AS C7_NUM , "
   _cQry += "  Case WHEN SFT.FT_TIPOMOV = 'E' THEN C7_OBSMREC Else 0 END AS C7_OBSMREC "

   _cQry += " FROM " + RetSqlName("SFT")+" SFT " 
   
   _cQry += "    LEFT JOIN "
   _cQry += " ( "

   _cQry += "     SELECT SF1.F1_FILIAL, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_FORNECE, SF1.F1_LOJA, SD1.D1_COD, SD1.D1_ITEM, "
   _cQry += "          (SF1.F1_TIPO) AS F1_TIPO, "
   _cQry += "          (D1_BASEIPI) D1_BASEIPI, "
   _cQry += "          (D1_IPI) D1_IPI, "
   _cQry += "          (D1_VALIPI) D1_VALIPI, "
   _cQry += "          (D1_DESPESA) D1_DESPESA, "
   _cQry += "          (D1_VALFRE) D1_VALFRE, "
   _cQry += "          (D1_SEGURO) D1_SEGURO, "
   _cQry += "          (D1_VUNIT) D1_VUNIT, "
   _cQry += "          (D1_TES) D1_TES, "
   _cQry += "          (D1_CC) D1_CC, "
   _cQry += "          (CTT_DESC01) CTT_DESC01, "
   _cQry += "          (D1_LOCAL) D1_LOCAL, "
   _cQry += "          (D1_UM) D1_UM, "
   _cQry += "          (D1_BASEISS) D1_BASEISS, "
   _cQry += "          (D1_ALIQISS) D1_ALIQISS, "
   _cQry += "          (D1_VALISS) D1_VALISS, "
   _cQry += "          (F4_DUPLIC) F4_DUPLIC, "
   _cQry += "          (F4_ESTOQUE) F4_ESTOQUE, "
   _cQry += "          (SA2.A2_NOME) AS SF1_A2_NOME, "
   _cQry += "          (SA2.A2_CGC) AS SF1_A2_CGC, "
   _cQry += "          (SA2.A2_INSCR) AS SF1_A2_INSCR, "
   _cQry += "          (SA2.A2_INSCRM) AS SF1_A2_IM, "
   _cQry += "          (SA2.A2_MUN) AS SF1_A2_MUN, "
   _cQry += "          (SA2.A2_EST) AS SF1_A2_EST, "
   _cQry += "          (SA2.A2_CALCIRF) AS SF1_A2_CALCIRF, "
   _cQry += "          (SA1.A1_NOME) AS SF1_A1_NOME, "
   _cQry += "          (SA1.A1_CGC) AS SF1_A1_CGC, "
   _cQry += "          (SA1.A1_INSCR) AS SF1_A1_INSCR, "
   _cQry += "          (SA1.A1_MUN) AS SF1_A1_MUN, "
   _cQry += "          (SA1.A1_EST) AS SF1_A1_EST, "
   _cQry += "          (SA1.A1_SIMPNAC) AS SF1_A1_SIMPNAC, "
   _cQry += "          (ED_CODIGO)ED_CODIGO , "
   _cQry += "          (ED_DESCRIC) ED_DESCRIC, "
   _cQry += "          (F4_FINALID) F4_FINALID "

   _cQry += "     FROM " + RetSqlName("SF1") + " SF1 "
   _cQry += "     LEFT JOIN " + RetSqlName("SD1") + " SD1 ON SF1.F1_FILIAL = SD1.D1_FILIAL AND SF1.F1_DOC     = SD1.D1_DOC AND SF1.F1_SERIE = SD1.D1_SERIE AND SF1.F1_FORNECE = SD1.D1_FORNECE AND SF1.F1_LOJA = SD1.D1_LOJA   AND SD1.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SF4") + " SF4 ON SF4.F4_FILIAL = SD1.D1_FILIAL AND SF4.F4_CODIGO = SD1.D1_TES AND SF4.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("CTT") + " CTT ON CTT.CTT_CUSTO = SD1.D1_CC AND CTT.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SA2") + " SA2 ON SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA  = SA2.A2_LOJA AND SA2.D_E_L_E_T_ = ' ' AND SF1.F1_TIPO  NOT IN ('D','B') "
   _cQry += "     LEFT JOIN " + RetSqlName("SA1") + " SA1 ON SF1.F1_FORNECE = SA1.A1_COD AND SF1.F1_LOJA  = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ' AND SF1.F1_TIPO  IN ('D','B')  "
   _cQry += "     LEFT JOIN ("

   _cQry += "        SELECT E2_FILIAL,E2_PREFIXO,E2_TIPO,E2_NUM, E2_FORNECE, E2_LOJA, E2_NATUREZ, ED_CODIGO, ED_DESCRIC "
   _cQry += "        FROM (SELECT E2_FILIAL,E2_PREFIXO,E2_TIPO,E2_NUM, E2_FORNECE, E2_LOJA,MIN(E2_NATUREZ) AS E2_NATUREZ "
   _cQry += "              FROM " + RetSqlName("SE2") + "  SE2 "
   _cQry += "              WHERE SE2.D_E_L_E_T_ = ' ' "
   _cQry += "              GROUP BY E2_FILIAL,E2_PREFIXO,E2_TIPO,E2_NUM, E2_FORNECE, E2_LOJA ) SE2
   _cQry += "        LEFT JOIN " + RetSqlName("SED") + " SED ON E2_NATUREZ = ED_CODIGO AND SED.D_E_L_E_T_ = ' ' "
   _cQry += "        ) SE2 ON SE2.E2_FILIAL = SF1.F1_FILIAL AND SE2.E2_NUM = SF1.F1_DOC AND SE2.E2_PREFIXO = SF1.F1_SERIE AND SE2.E2_FORNECE = SF1.F1_FORNECE AND SE2.E2_LOJA = SF1.F1_LOJA "
   _cQry += "     WHERE SF1.D_E_L_E_T_ = ' ' "
   
   _cQry += " ) SF1 ON SFT.FT_FILIAL = SF1.F1_FILIAL AND SFT.FT_NFISCAL = SF1.F1_DOC AND SFT.FT_SERIE = SF1.F1_SERIE AND SFT.FT_CLIEFOR = SF1.F1_FORNECE AND SFT.FT_LOJA = SF1.F1_LOJA AND SFT.FT_PRODUTO = SF1.D1_COD AND SFT.FT_ITEM = SF1.D1_ITEM  AND CAST(SFT.FT_CFOP AS NUMERIC) < 5000 "
   
   _cQry += "    LEFT JOIN "
   
   _cQry += " ( "
   _cQry += "     SELECT SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA, D2_COD, D2_ITEM, "
   _cQry += "        (SF2.F2_TIPO) F2_TIPO, "
   _cQry += "        (F2_I_PLACA) F2_I_PLACA, "
   _cQry += "        (F2_I_FRET) F2_I_FRET, "
   _cQry += "        (F2_TPFRETE) F2_TPFRETE, "
   _cQry += "        (F2_I_CTRA) F2_I_CTRA, "
   _cQry += "        (F2_I_LTRA) F2_I_LTRA, "
   _cQry += "        (D2_BASEIPI) D2_BASEIPI, "
   _cQry += "        (D2_IPI) D2_IPI, "
   _cQry += "        (D2_VALIPI) D2_VALIPI, "
   _cQry += "        (D2_DESPESA) D2_DESPESA, "
   _cQry += "        (D2_VALFRE) D2_VALFRE, "
   _cQry += "        (D2_SEGURO) D2_SEGURO, "
   _cQry += "        (D2_PRUNIT) D2_PRUNIT, "
   _cQry += "        (D2_TES) D2_TES, "
   _cQry += "        (D2_CCUSTO) D2_CCUSTO, "
   _cQry += "        (CTT_DESC01) CTT_DESC01, "
   _cQry += "        (D2_LOCAL) D2_LOCAL, "
   _cQry += "        (D2_UM) D2_UM, "
   _cQry += "        (D2_BASEISS) D2_BASEISS, "
   _cQry += "        (D2_ALIQISS) D2_ALIQISS, "
   _cQry += "        (D2_VALISS) D2_VALISS, "
   _cQry += "        (F4_DUPLIC) F4_DUPLIC, "
   _cQry += "        (F4_ESTOQUE) F4_ESTOQUE, "
   _cQry += "        (SA1.A1_NOME) AS SF2_A1_NOME, "
   _cQry += "        (SA1.A1_CGC) AS SF2_A1_CGC, "
   _cQry += "        (SA1.A1_INSCR) AS SF2_A1_INSCR, "
   _cQry += "        (SA1.A1_MUN) AS SF2_A1_MUN, "
   _cQry += "        (SA1.A1_EST) AS SF2_A1_EST, "
   _cQry += "        (SA1.A1_SIMPNAC) AS SF2_A1_SIMPNAC, "
   _cQry += "        (SA2.A2_NOME) AS SF2_A2_NOME, "
   _cQry += "        (SA2.A2_CGC) AS SF2_A2_CGC, "
   _cQry += "        (SA2.A2_INSCR) AS SF2_A2_INSCR, "
   _cQry += "        (SA2.A2_INSCRM) AS SF2_A2_INSCM, "
   _cQry += "        (SA2.A2_MUN) AS SF2_A2_MUN, "
   _cQry += "        (SA2.A2_EST) AS SF2_A2_EST, "
   _cQry += "        (SA2.A2_CALCIRF) AS SF2_A2_CALCIRF, "
   _cQry += "        (SA2T.A2_NOME) AS SF2T_A2_NOME, "
   _cQry += "        (SA2T.A2_MUN) AS SF2T_A2_MUN, "
   _cQry += "        (SA2T.A2_EST) AS SF2T_A2_EST, "
   _cQry += "        (F4_FINALID) F4_FINALID " 
   _cQry += "     FROM " + RetSqlName("SF2") + " SF2 "
   _cQry += "     LEFT JOIN " + RetSqlName("SD2") + " SD2 ON SF2.F2_FILIAL = SD2.D2_FILIAL AND SF2.F2_DOC     = SD2.D2_DOC AND SF2.F2_SERIE = SD2.D2_SERIE AND SF2.F2_CLIENTE = SD2.D2_CLIENTE AND SF2.F2_LOJA = SD2.D2_LOJA AND SD2.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SF4") + " SF4_2 ON SF4_2.F4_FILIAL = SD2.D2_FILIAL AND SF4_2.F4_CODIGO = SD2.D2_TES AND SF4_2.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("CTT") + " CTT_2 ON CTT_2.CTT_CUSTO = SD2.D2_CCUSTO AND CTT_2.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SA2") + " SA2 ON SF2.F2_CLIENTE = SA2.A2_COD AND SF2.F2_LOJA  = SA2.A2_LOJA AND SA2.D_E_L_E_T_ = ' ' AND SF2.F2_TIPO  IN ('D','B') "
   _cQry += "     LEFT JOIN " + RetSqlName("SA1") + " SA1 ON SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA  = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ' AND SF2.F2_TIPO  NOT IN ('D','B') "
   _cQry += "     LEFT JOIN " + RetSqlName("SA2") + " SA2T ON SF2.F2_I_CTRA = SA2T.A2_COD AND SF2.F2_I_LTRA  = SA2T.A2_LOJA AND SA2T.D_E_L_E_T_ = ' ' AND SF2.F2_I_CTRA <> ' ' "
   _cQry += "     WHERE SF2.D_E_L_E_T_ = ' ' "
   _cQry += " ) SF2 ON SFT.FT_FILIAL = SF2.F2_FILIAL AND SFT.FT_NFISCAL = SF2.F2_DOC AND SFT.FT_SERIE = SF2.F2_SERIE AND SFT.FT_CLIEFOR = SF2.F2_CLIENTE AND SFT.FT_LOJA = SF2.F2_LOJA AND SFT.FT_PRODUTO = SF2.D2_COD AND SFT.FT_ITEM = SF2.D2_ITEM AND SFT.FT_CFOP > '5000' "
   
   _cQry += "    LEFT JOIN " + RetSqlName("SB1") + " SB1 ON SFT.FT_PRODUTO = SB1.B1_COD AND SB1.D_E_L_E_T_ = ' ' "
   _cQry += "    LEFT JOIN " + RetSqlName("SBM") + " SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO AND SBM.D_E_L_E_T_ = ' '"

   _cQry += "    LEFT JOIN "
   _cQry += " ( "
   _cQry += "    SELECT M0_CODIGO, M0_CODFIL, M0_CGC, M0_FILIAL AS M0_NOME, (M0_INSC) AS M0_INSCR, (M0_INSCM) AS M0_INSCRM, (M0_CIDENT) AS M0_MUN, (M0_ESTENT) AS M0_EST "
   _cQry += "    FROM SIGA.SYS_COMPANY SM0 "
   _cQry += "    ) SM0 ON M0_CODFIL = SFT.FT_FILIAL "

   _cQry += "    LEFT JOIN "
   _cQry += " ( "
   _cQry += "    SELECT F3_FILIAL, F3_CLIEFOR, F3_LOJA, F3_NFISCAL, F3_SERIE, F3_ENTRADA, MIN(F3_CODRSEF) F3_CODRSEF "
   _cQry += "    FROM " + RetSqlName("SF3") + " SF3 "
   _cQry += "    WHERE SF3.D_E_L_E_T_ = ' ' "
   _cQry += "    GROUP BY  SF3.F3_FILIAL,SF3.F3_CLIEFOR, SF3.F3_LOJA,SF3.F3_NFISCAL,SF3.F3_SERIE,SF3.F3_ENTRADA
   _cQry += "    ) SF3 ON SFT.FT_FILIAL = SF3.F3_FILIAL  AND SFT.FT_CLIEFOR = SF3.F3_CLIEFOR AND SFT.FT_LOJA = SF3.F3_LOJA AND SFT.FT_NFISCAL = SF3.F3_NFISCAL AND SFT.FT_SERIE = SF3.F3_SERIE AND SFT.FT_ENTRADA = SF3.F3_ENTRADA "



   _cQry += "    LEFT JOIN ( SELECT SD2_2.D2_FILIAL, SD2_2.D2_DOC,SD2_2.D2_SERIE,SD2_2.D2_CLIENTE,SD2_2.D2_LOJA, COUNT(*) AS QTD_ITENS "
   _cQry += "                   FROM SD2010 SD2_2  "
   _cQry += "                   WHERE SD2_2.D_E_L_E_T_ = ' ' "
   _cQry += "                   GROUP BY SD2_2.D2_FILIAL, SD2_2.D2_DOC,SD2_2.D2_SERIE,SD2_2.D2_CLIENTE,SD2_2.D2_LOJA ) SD2_2 ON SF2.F2_FILIAL = SD2_2.D2_FILIAL AND SF2.F2_DOC     = SD2_2.D2_DOC AND SF2.F2_SERIE = SD2_2.D2_SERIE AND SF2.F2_CLIENTE = SD2_2.D2_CLIENTE AND SF2.F2_LOJA = SD2_2.D2_LOJA "

   _cQry += "    LEFT JOIN (SELECT D1_FILIAL, D1_PEDIDO, D1_FORNECE, D1_LOJA, D1_ITEMPC, D1_ITEM, D1_DOC, D1_SERIE
   _cQry += "    FROM " + RetSqlName("SD1") + " SD1_2 "
   _cQry += "    WHERE SD1_2.D_E_L_E_T_ = ' ' ) SD1_2 ON SFT.FT_FILIAL = SD1_2.D1_FILIAL AND SFT.FT_CLIEFOR = SD1_2.D1_FORNECE AND SFT.FT_LOJA = SD1_2.D1_LOJA AND SFT.FT_ITEM = SD1_2.D1_ITEM "
   _cQry += "    AND SFT.FT_NFISCAL = SD1_2.D1_DOC AND SFT.FT_SERIE = SD1_2.D1_SERIE "

   _cQry += "    LEFT JOIN (SELECT C7_FILIAL, C7_NUM, C7_FORNECE, C7_LOJA, C7_ITEM, SC7.R_E_C_N_O_ C7_OBSMREC "
   _cQry += "    FROM " + RetSqlName("SC7") + " SC7 " 
   _cQry += "    WHERE SC7.D_E_L_E_T_ = ' ') SC7 ON SC7.C7_FILIAL = SD1_2.D1_FILIAL AND SC7.C7_FORNECE = SD1_2.D1_FORNECE AND SC7.C7_LOJA = SD1_2.D1_LOJA AND SC7.C7_ITEM = SD1_2.D1_ITEMPC AND SC7.C7_NUM = SD1_2.D1_PEDIDO "

   _cQry += " WHERE  SFT.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SFT.FT_OBSERV <> 'NF CANCELADA                   ' "


   _cQry += " UNION ALL "


   _cQry += " SELECT FT_FILIAL, "
   _cQry += "  FT_EMISSAO,		"
   _cQry += "  FT_ENTRADA,		"
   _cQry += "  FT_NFISCAL,		"
   _cQry += "  FT_SERIE,		"
   _cQry += "  FT_ESPECIE,		"
   _cQry += "  FT_CHVNFE,		"
   _cQry += "  SF3.F3_CODRSEF,		"
   _cQry += "  FT_TIPOMOV,		"
   _cQry += "  FT_TIPO,		"
   _cQry += "  D1_TES,		"
   _cQry += "  FT_CFOP,		"
   _cQry += "  FT_NFORI,		"
   _cQry += "  FT_SERORI,		"
   _cQry += "  FT_OBSERV,		"
   _cQry += "  FT_CLIEFOR,		"
   _cQry += "  FT_LOJA,		"
   _cQry += "  FT_PRODUTO,		"
   _cQry += "  FT_ITEM,		"
   _cQry += "  FT_POSIPI,		"
   _cQry += "  FT_QUANT,		"
   _cQry += "  FT_PRCUNIT,		"
   _cQry += "  FT_DESCONT,		"
   _cQry += "  FT_DESPESA,		"
   _cQry += "  FT_FRETE,		"
   _cQry += "  FT_SEGURO,		"
   _cQry += "  FT_TOTAL,		"
   _cQry += "  FT_VALCONT,		"
   _cQry += "  FT_CLASFIS,		"
   _cQry += "  FT_BASEICM,		"
   _cQry += "  FT_ALIQICM,		"
   _cQry += "  FT_VALICM,		"
   _cQry += "  FT_BASERET,		"
   _cQry += "  FT_ALIQSOL,		"
   _cQry += "  FT_MARGEM,		"
   _cQry += "  FT_ICMSRET,		"
   _cQry += "  FT_BASEDES,		"
   _cQry += "  FT_ICMSCOM,		"
   _cQry += "  FT_CTIPI,		"
   _cQry += "  FT_BASEIPI,		"
   _cQry += "  FT_ALIQIPI,		"
   _cQry += "  FT_VALIPI,		"
   _cQry += "  FT_CSTPIS,		"
   _cQry += "  FT_BASEPIS,		"
   _cQry += "  FT_ALIQPIS,		"
   _cQry += "  FT_VALPIS,		"
   _cQry += "  FT_CSTCOF,		"
   _cQry += "  FT_BASECOF,		"
   _cQry += "  FT_ALIQCOF,		"
   _cQry += "  FT_VALCOF,		"
   _cQry += "  FT_VALIRR,		"
   _cQry += "  FT_VALINS,		"
   _cQry += "  FT_VRETCSL,		"
   _cQry += "  FT_VRETPIS,		"
   _cQry += "  FT_VRETCOF,		"
   _cQry += "  0 AS D1_VALISS,		"
   _cQry += "  FT_VALFUM,		"
   _cQry += "  FT_VLSENAR,		"
   _cQry += "  FT_VALFUND,		"
   _cQry += "  FT_VALANTI,		"
   _cQry += "  FT_DTCANC, "
   _cQry += "  F1_FILIAL, "
   _cQry += "  F1_FORNECE, "
   _cQry += "  F1_LOJA, "
   _cQry += "  F1_SERIE, "
   _cQry += "  F1_DOC, "
   _cQry += "  SF1.D1_BASEIPI , "
   _cQry += "  SF1.D1_IPI, "
   _cQry += "  SF1.D1_VALIPI, "
   _cQry += "  SF1.D1_DESPESA, "
   _cQry += "  SF1.D1_VALFRE, "
   _cQry += "  SF1.D1_SEGURO, "
   _cQry += "  SF1.D1_VUNIT, "
   _cQry += "  SF1.D1_CC, "
   _cQry += "  SF1.CTT_DESC01 AS SF1_DESC01, "
   _cQry += "  SF1.D1_LOCAL, "
   _cQry += "  SF1.D1_UM, "
   _cQry += "  SF1.D1_BASEISS, "
   _cQry += "  SF1.D1_ALIQISS, "
   _cQry += "  SF1.D1_VALISS AS SF1_VALISS, "
   _cQry += "  SF1.F4_DUPLIC AS SF1_DUPLIC, "
   _cQry += "  SF1.F4_ESTOQUE AS SF1_ESTOQUE, "
   _cQry += "  SF1.F4_FINALID AS SF1_FINALID,"
   _cQry += "  SF1.SF1_A2_NOME, "
   _cQry += "  SF1.SF1_A2_INSCR,  "
   _cQry += "  SF1.SF1_A2_IM, "
   _cQry += "  SF1.SF1_A2_MUN, "
   _cQry += "  SF1.SF1_A2_EST,  "
   _cQry += "  SF1.SF1_A2_CGC, "
   _cQry += "  SF1.SF1_A2_CALCIRF, "
   _cQry += "  SF1.SF1_A1_NOME, "
   _cQry += "  SF1.SF1_A1_INSCR,  "
   _cQry += "  SF1.SF1_A1_MUN, "
   _cQry += "  SF1.SF1_A1_EST, "
   _cQry += "  SF1.SF1_A1_CGC, "
   _cQry += "  SF1.SF1_A1_SIMPNAC, "
   _cQry += "  SF1.F1_TIPO, "
   _cQry += "  (Case WHEN SF1.F1_TIPO  IN ('D','B') THEN 'DEV' Else ' ' END) AS SF1_DEV, "
   _cQry += "  ED_CODIGO, "
   _cQry += "  ED_DESCRIC, "
   _cQry += "  F2_I_CTRA,		"
   _cQry += "  F2_I_LTRA,		"
   _cQry += "  F2_I_PLACA,		"
   _cQry += "  F2_I_FRET,		"
   _cQry += "  F2_TPFRETE,		"
   _cQry += "  SF2.D2_BASEIPI, "
   _cQry += "  SF2.D2_IPI, "
   _cQry += "  SF2.D2_VALIPI, "
   _cQry += "  SF2.D2_DESPESA, "
   _cQry += "  SF2.D2_VALFRE, "
   _cQry += "  SF2.D2_SEGURO, "
   _cQry += "  SF2.D2_PRUNIT, "
   _cQry += "  SF2.D2_TES, "
   _cQry += "  SF2.D2_CCUSTO, "
   _cQry += "  SF2.CTT_DESC01 AS SF2_DESC01, "
   _cQry += "  SF2.D2_LOCAL, "
   _cQry += "  SF2.D2_UM, "
   _cQry += "  SF2.D2_BASEISS, "
   _cQry += "  SF2.D2_ALIQISS, "
   _cQry += "  SF2.D2_VALISS, "
   _cQry += "  SF2.F4_DUPLIC AS SF2_DUPLIC, "
   _cQry += "  SF2.F4_ESTOQUE AS SF2_ESTOQUE, "
   _cQry += "  SF2.F4_FINALID AS SF2_FINALID, "
   _cQry += "  SF2.SF2_A1_NOME, "
   _cQry += "  SF2.SF2_A1_INSCR,  "
   _cQry += "  SF2.SF2_A1_MUN, "
   _cQry += "  SF2.SF2_A1_EST, "
   _cQry += "  SF2.SF2_A1_CGC, "
   _cQry += "  SF2.SF2_A1_SIMPNAC, "
   _cQry += "  SF2.SF2_A2_NOME, "
   _cQry += "  SF2.SF2_A2_INSCR,  "
   _cQry += "  SF2.SF2_A2_INSCM, "
   _cQry += "  SF2.SF2_A2_MUN, "
   _cQry += "  SF2.SF2_A2_EST,  "
   _cQry += "  SF2.SF2_A2_CGC, "
   _cQry += "  SF2.SF2_A2_CALCIRF, "
   _cQry += "  SF2.SF2T_A2_NOME, "
   _cQry += "  SF2.SF2T_A2_MUN, "
   _cQry += "  SF2.SF2T_A2_EST,  "
   _cQry += "  SF2.F2_TIPO, "
   _cQry += "  (Case WHEN SF2.F2_TIPO  IN ('D','B') THEN 'DEV' Else ' ' END) AS SF2_DEV ,"
   _cQry += "  M0_CODIGO, "
   _cQry += "  M0_CODFIL, "
   _cQry += "  M0_CGC, "
   _cQry += "  M0_NOME, "
   _cQry += "  M0_INSCR, "
   _cQry += "  M0_INSCRM, "
   _cQry += "  M0_MUN, "
   _cQry += "  M0_EST, "
   _cQry += "  B1_DESC,		"
   _cQry += "  B1_GRUPO,	"
   _cQry += "  BM_DESC,		"
   _cQry += "  SD2_2.QTD_ITENS, "
   _cQry += "  SD1_2.D1_FILIAL,  "
   _cQry += "  SD1_2.D1_PEDIDO,  "
   _cQry += "  SD1_2.D1_FORNECE ,"
   _cQry += "  SD1_2.D1_LOJA,    "
   _cQry += "  SD1_2.D1_ITEMPC,  "
   _cQry += "  Case WHEN SFT.FT_TIPOMOV = 'E' THEN C7_NUM Else ' ' END AS C7_NUM , "
   _cQry += "  Case WHEN SFT.FT_TIPOMOV = 'E' THEN C7_OBSMREC Else 0 END AS C7_OBSMREC "

   _cQry += " FROM " + RetSqlName("SFT") + " SFT " 
   
   _cQry += "    LEFT JOIN "
   _cQry += " ( "

   _cQry += "     SELECT SF1.F1_FILIAL, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_FORNECE, SF1.F1_LOJA, SD1.D1_COD, SD1.D1_ITEM, "
   _cQry += "          (SF1.F1_TIPO) AS F1_TIPO, "
   _cQry += "          (D1_BASEIPI) D1_BASEIPI, "
   _cQry += "          (D1_IPI) D1_IPI, "
   _cQry += "          (D1_VALIPI) D1_VALIPI, "
   _cQry += "          (D1_DESPESA) D1_DESPESA, "
   _cQry += "          (D1_VALFRE) D1_VALFRE, "
   _cQry += "          (D1_SEGURO) D1_SEGURO, "
   _cQry += "          (D1_VUNIT) D1_VUNIT, "
   _cQry += "          (D1_TES) D1_TES, "
   _cQry += "          (D1_CC) D1_CC, "
   _cQry += "          (CTT_DESC01) CTT_DESC01, "
   _cQry += "          (D1_LOCAL) D1_LOCAL, "
   _cQry += "          (D1_UM) D1_UM, "
   _cQry += "          (D1_BASEISS) D1_BASEISS, "
   _cQry += "          (D1_ALIQISS) D1_ALIQISS, "
   _cQry += "          (D1_VALISS) D1_VALISS, "
   _cQry += "          (F4_DUPLIC) F4_DUPLIC, "
   _cQry += "          (F4_ESTOQUE) F4_ESTOQUE, "
   _cQry += "          (SA2.A2_NOME) AS SF1_A2_NOME, "
   _cQry += "          (SA2.A2_CGC) AS SF1_A2_CGC, "
   _cQry += "          (SA2.A2_INSCR) AS SF1_A2_INSCR, "
   _cQry += "          (SA2.A2_INSCRM) AS SF1_A2_IM, "
   _cQry += "          (SA2.A2_MUN) AS SF1_A2_MUN, "
   _cQry += "          (SA2.A2_EST) AS SF1_A2_EST, "
   _cQry += "          (SA2.A2_CALCIRF) AS SF1_A2_CALCIRF, "
   _cQry += "          (SA1.A1_NOME) AS SF1_A1_NOME, "
   _cQry += "          (SA1.A1_CGC) AS SF1_A1_CGC, "
   _cQry += "          (SA1.A1_INSCR) AS SF1_A1_INSCR, "
   _cQry += "          (SA1.A1_MUN) AS SF1_A1_MUN, "
   _cQry += "          (SA1.A1_EST) AS SF1_A1_EST, "
   _cQry += "          (SA1.A1_SIMPNAC) AS SF1_A1_SIMPNAC, "
   _cQry += "          (ED_CODIGO)ED_CODIGO , "
   _cQry += "          (ED_DESCRIC) ED_DESCRIC, "
   _cQry += "          (F4_FINALID) F4_FINALID "

   _cQry += "     FROM " + RetSqlName("SF1") + " SF1 "
   _cQry += "     LEFT JOIN " + RetSqlName("SD1") + " SD1 ON SF1.F1_FILIAL = SD1.D1_FILIAL AND SF1.F1_DOC     = SD1.D1_DOC AND SF1.F1_SERIE = SD1.D1_SERIE AND SF1.F1_FORNECE = SD1.D1_FORNECE AND SF1.F1_LOJA = SD1.D1_LOJA   AND SD1.D_E_L_E_T_ = '*' "
   _cQry += "     LEFT JOIN " + RetSqlName("SF4") + " SF4 ON SF4.F4_FILIAL = SD1.D1_FILIAL AND SF4.F4_CODIGO = SD1.D1_TES AND SF4.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("CTT") + " CTT ON CTT.CTT_CUSTO = SD1.D1_CC AND CTT.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SA2") + " SA2 ON SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA  = SA2.A2_LOJA AND SA2.D_E_L_E_T_ = ' ' AND SF1.F1_TIPO  NOT IN ('D','B') "
   _cQry += "     LEFT JOIN " + RetSqlName("SA1") + " SA1 ON SF1.F1_FORNECE = SA1.A1_COD AND SF1.F1_LOJA  = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ' AND SF1.F1_TIPO  IN ('D','B')  "
   _cQry += "     LEFT JOIN ("

   _cQry += "        SELECT E2_FILIAL,E2_PREFIXO,E2_TIPO,E2_NUM, E2_FORNECE, E2_LOJA, E2_NATUREZ, ED_CODIGO, ED_DESCRIC
   _cQry += "        FROM (SELECT E2_FILIAL,E2_PREFIXO,E2_TIPO,E2_NUM, E2_FORNECE, E2_LOJA,MIN(E2_NATUREZ) AS E2_NATUREZ 
   _cQry += "              FROM " + RetSqlName("SE2") + "  SE2 
   _cQry += "              GROUP BY E2_FILIAL,E2_PREFIXO,E2_TIPO,E2_NUM, E2_FORNECE, E2_LOJA ) SE2
   _cQry += "        LEFT JOIN " + RetSqlName("SED") + " SED ON E2_NATUREZ = ED_CODIGO 
   _cQry += "        ) SE2 ON SE2.E2_FILIAL = SF1.F1_FILIAL AND SE2.E2_NUM = SF1.F1_DOC AND SE2.E2_PREFIXO = SF1.F1_SERIE AND SE2.E2_FORNECE = SF1.F1_FORNECE AND SE2.E2_LOJA = SF1.F1_LOJA "
   _cQry += "     WHERE SF1.D_E_L_E_T_ = '*' "
   _cQry += " ) SF1 ON SFT.FT_FILIAL = SF1.F1_FILIAL AND SFT.FT_NFISCAL = SF1.F1_DOC AND SFT.FT_SERIE = SF1.F1_SERIE AND SFT.FT_CLIEFOR = SF1.F1_FORNECE AND SFT.FT_LOJA = SF1.F1_LOJA AND SFT.FT_PRODUTO = SF1.D1_COD AND SFT.FT_ITEM = SF1.D1_ITEM  AND CAST(SFT.FT_CFOP AS NUMERIC) < 5000 "
   
   _cQry += "    LEFT JOIN "
   
   _cQry += " ( "
   _cQry += "     SELECT SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA, D2_COD, D2_ITEM, "
   _cQry += "        (SF2.F2_TIPO) F2_TIPO, "
   _cQry += "        (F2_I_PLACA) F2_I_PLACA, "
   _cQry += "        (F2_I_FRET) F2_I_FRET, "
   _cQry += "        (F2_TPFRETE) F2_TPFRETE, "
   _cQry += "        (F2_I_CTRA) F2_I_CTRA, "
   _cQry += "        (F2_I_LTRA) F2_I_LTRA, "
   _cQry += "        (D2_BASEIPI) D2_BASEIPI, "
   _cQry += "        (D2_IPI) D2_IPI, "
   _cQry += "        (D2_VALIPI) D2_VALIPI, "
   _cQry += "        (D2_DESPESA) D2_DESPESA, "
   _cQry += "        (D2_VALFRE) D2_VALFRE, "
   _cQry += "        (D2_SEGURO) D2_SEGURO, "
   _cQry += "        (D2_PRUNIT) D2_PRUNIT, "
   _cQry += "        (D2_TES) D2_TES, "
   _cQry += "        (D2_CCUSTO) D2_CCUSTO, "
   _cQry += "        (CTT_DESC01) CTT_DESC01, "
   _cQry += "        (D2_LOCAL) D2_LOCAL, "
   _cQry += "        (D2_UM) D2_UM, "
   _cQry += "        (D2_BASEISS) D2_BASEISS, "
   _cQry += "        (D2_ALIQISS) D2_ALIQISS, "
   _cQry += "        (D2_VALISS) D2_VALISS, "
   _cQry += "        (F4_DUPLIC) F4_DUPLIC, "
   _cQry += "        (F4_ESTOQUE) F4_ESTOQUE, "
   _cQry += "        (SA1.A1_NOME) AS SF2_A1_NOME, "
   _cQry += "        (SA1.A1_CGC) AS SF2_A1_CGC, "
   _cQry += "        (SA1.A1_INSCR) AS SF2_A1_INSCR, "
   _cQry += "        (SA1.A1_MUN) AS SF2_A1_MUN, "
   _cQry += "        (SA1.A1_EST) AS SF2_A1_EST, "
   _cQry += "        (SA1.A1_SIMPNAC) AS SF2_A1_SIMPNAC, "
   _cQry += "        (SA2.A2_NOME) AS SF2_A2_NOME, "
   _cQry += "        (SA2.A2_CGC) AS SF2_A2_CGC, "
   _cQry += "        (SA2.A2_INSCR) AS SF2_A2_INSCR, "
   _cQry += "        (SA2.A2_INSCRM) AS SF2_A2_INSCM, "
   _cQry += "        (SA2.A2_MUN) AS SF2_A2_MUN, "
   _cQry += "        (SA2.A2_EST) AS SF2_A2_EST, "
   _cQry += "        (SA2.A2_CALCIRF) AS SF2_A2_CALCIRF, "
   _cQry += "        (SA2T.A2_NOME) AS SF2T_A2_NOME, "
   _cQry += "        (SA2T.A2_MUN) AS SF2T_A2_MUN, "
   _cQry += "        (SA2T.A2_EST) AS SF2T_A2_EST, "
   _cQry += "        (F4_FINALID) F4_FINALID " 
   _cQry += "     FROM " + RetSqlName("SF2") + " SF2 "
   _cQry += "     LEFT JOIN " + RetSqlName("SD2") + " SD2 ON SF2.F2_FILIAL = SD2.D2_FILIAL AND SF2.F2_DOC     = SD2.D2_DOC AND SF2.F2_SERIE = SD2.D2_SERIE AND SF2.F2_CLIENTE = SD2.D2_CLIENTE AND SF2.F2_LOJA = SD2.D2_LOJA AND SD2.D_E_L_E_T_ = '*' "
   _cQry += "     LEFT JOIN " + RetSqlName("SF4") + " SF4_2 ON SF4_2.F4_FILIAL = SD2.D2_FILIAL AND SF4_2.F4_CODIGO = SD2.D2_TES AND SF4_2.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("CTT") + " CTT_2 ON CTT_2.CTT_CUSTO = SD2.D2_CCUSTO AND CTT_2.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SA2") + " SA2 ON SF2.F2_CLIENTE = SA2.A2_COD AND SF2.F2_LOJA  = SA2.A2_LOJA AND SA2.D_E_L_E_T_ = ' ' AND SF2.F2_TIPO  IN ('D','B') "
   _cQry += "     LEFT JOIN " + RetSqlName("SA1") + " SA1 ON SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA  = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ' AND SF2.F2_TIPO  NOT IN ('D','B') "
   _cQry += "     LEFT JOIN " + RetSqlName("SA2") + " SA2T ON SF2.F2_I_CTRA = SA2T.A2_COD AND SF2.F2_I_LTRA  = SA2T.A2_LOJA AND SA2T.D_E_L_E_T_ = ' ' AND SF2.F2_I_CTRA <> ' ' "
   _cQry += "     WHERE SF2.D_E_L_E_T_ = '*' "
   _cQry += " ) SF2 ON SFT.FT_FILIAL = SF2.F2_FILIAL AND SFT.FT_NFISCAL = SF2.F2_DOC AND SFT.FT_SERIE = SF2.F2_SERIE AND SFT.FT_CLIEFOR = SF2.F2_CLIENTE AND SFT.FT_LOJA = SF2.F2_LOJA AND SFT.FT_PRODUTO = SF2.D2_COD AND SFT.FT_ITEM = SF2.D2_ITEM AND SFT.FT_CFOP > '5000' "

   _cQry += "    LEFT JOIN " + RetSqlName("SB1") + " SB1 ON SFT.FT_PRODUTO = SB1.B1_COD AND SB1.D_E_L_E_T_ = ' ' "
   _cQry += "    LEFT JOIN " + RetSqlName("SBM") + " SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO AND SBM.D_E_L_E_T_ = ' '"

   _cQry += "    LEFT JOIN "
   _cQry += " ( "
   _cQry += "    SELECT M0_CODIGO, M0_CODFIL, M0_CGC, M0_FILIAL AS M0_NOME, (M0_INSC) AS M0_INSCR, (M0_INSCM) AS M0_INSCRM, (M0_CIDENT) AS M0_MUN, (M0_ESTENT) AS M0_EST "
   _cQry += "    FROM SIGA.SYS_COMPANY SM0 "
   _cQry += "    ) SM0 ON M0_CODFIL = SFT.FT_FILIAL "

   _cQry += "    LEFT JOIN "
   _cQry += " ( "
   _cQry += "    SELECT F3_FILIAL, F3_CLIEFOR, F3_LOJA, F3_NFISCAL, F3_SERIE, F3_ENTRADA, MIN(F3_CODRSEF) F3_CODRSEF "
   _cQry += "    FROM " + RetSqlName("SF3") + " SF3 "
   _cQry += "    WHERE SF3.D_E_L_E_T_ = ' ' "
   _cQry += "    GROUP BY  SF3.F3_FILIAL,SF3.F3_CLIEFOR, SF3.F3_LOJA,SF3.F3_NFISCAL,SF3.F3_SERIE,SF3.F3_ENTRADA
   _cQry += "    ) SF3 ON SFT.FT_FILIAL = SF3.F3_FILIAL  AND SFT.FT_CLIEFOR = SF3.F3_CLIEFOR AND SFT.FT_LOJA = SF3.F3_LOJA AND SFT.FT_NFISCAL = SF3.F3_NFISCAL AND SFT.FT_SERIE = SF3.F3_SERIE AND SFT.FT_ENTRADA = SF3.F3_ENTRADA "



   _cQry += "    LEFT JOIN ( SELECT SD2_2.D2_FILIAL, SD2_2.D2_DOC,SD2_2.D2_SERIE,SD2_2.D2_CLIENTE,SD2_2.D2_LOJA, COUNT(*) AS QTD_ITENS "
   _cQry += "                   FROM SD2010 SD2_2  "
   _cQry += "                   WHERE SD2_2.D_E_L_E_T_ = ' ' "
   _cQry += "                   GROUP BY SD2_2.D2_FILIAL, SD2_2.D2_DOC,SD2_2.D2_SERIE,SD2_2.D2_CLIENTE,SD2_2.D2_LOJA ) SD2_2 ON SF2.F2_FILIAL = SD2_2.D2_FILIAL AND SF2.F2_DOC     = SD2_2.D2_DOC AND SF2.F2_SERIE = SD2_2.D2_SERIE AND SF2.F2_CLIENTE = SD2_2.D2_CLIENTE AND SF2.F2_LOJA = SD2_2.D2_LOJA "

   _cQry += "    LEFT JOIN (SELECT D1_FILIAL, D1_PEDIDO, D1_FORNECE, D1_LOJA, D1_ITEMPC, D1_ITEM, D1_DOC, D1_SERIE
   _cQry += "    FROM " + RetSqlName("SD1") + " SD1_2 "
   _cQry += "    WHERE SD1_2.D_E_L_E_T_ = ' ' ) SD1_2 ON SFT.FT_FILIAL = SD1_2.D1_FILIAL AND SFT.FT_CLIEFOR = SD1_2.D1_FORNECE AND SFT.FT_LOJA = SD1_2.D1_LOJA AND SFT.FT_ITEM = SD1_2.D1_ITEM "
   _cQry += "    AND SFT.FT_NFISCAL = SD1_2.D1_DOC AND SFT.FT_SERIE = SD1_2.D1_SERIE "

   _cQry += "    LEFT JOIN (SELECT C7_FILIAL, C7_NUM, C7_FORNECE, C7_LOJA, C7_ITEM, SC7.R_E_C_N_O_ C7_OBSMREC "
   _cQry += "    FROM " + RetSqlName("SC7") + " SC7 " 
   _cQry += "    WHERE SC7.D_E_L_E_T_ = ' ') SC7 ON SC7.C7_FILIAL = SD1_2.D1_FILIAL AND SC7.C7_FORNECE = SD1_2.D1_FORNECE AND SC7.C7_LOJA = SD1_2.D1_LOJA AND SC7.C7_ITEM = SD1_2.D1_ITEMPC AND SC7.C7_NUM = SD1_2.D1_PEDIDO "

   _cQry += " WHERE  SFT.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SFT.FT_OBSERV = 'NF CANCELADA                   ' "

   _cQry +=  " ) QRY "

   _cWhere := " WHERE  0 = 0 "
             
   If ! Empty(MV_PAR05)      
      _cWhere +=  " AND B1_GRUPO = '"+MV_PAR05+"' "
   EndIf

   If ! Empty(MV_PAR01)
      _cWhere +=  " AND FT_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";")
   EndIf              
   
   If ! Empty(MV_PAR02)        
      _cWhere +=  " AND FT_ENTRADA >= '"+DToS(MV_PAR02)+"' "
   EndIf
   
   If ! Empty(MV_PAR03)        
      _cWhere +=  " AND FT_ENTRADA <= '"+DToS(MV_PAR03)+"' "
   EndIf

   If ! Empty(MV_PAR07)
      _cWhere +=  " AND FT_CFOP IN " + FormatIn(AllTrim(MV_PAR07),";")
   EndIf              

   If MV_PAR06 = 1
      _cWhere +=  " AND FT_TIPOMOV = 'E' "
   ElseIf MV_PAR06 = 2
      _cWhere +=  " AND FT_TIPOMOV = 'S' "
   EndIf

   //=========================================		
   // Forncedor De - Ate 
   //=========================================
   If !Empty(MV_PAR10)	
   	_cWhere  += " AND FT_CLIEFOR BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR10 + "'"
   ElseIf !Empty(MV_PAR08) 
   	_cWhere  += " AND FT_CLIEFOR >= '" + MV_PAR08 + "' "
   EndIf                                                             
   
   //=========================================		
   // Loja Forncedor De - Ate
   //=========================================
   If !Empty(MV_PAR11)	
   	_cWhere  += " AND FT_LOJA BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR11 + "'"
   ElseIf !Empty(MV_PAR09) 
   	_cWhere  += " AND FT_LOJA >= '" + MV_PAR09 + "' "
   EndIf             
   
   //=========================================		
   // Cliente De - Ate 
   //=========================================
   If !Empty(MV_PAR14)	
   	_cWhere  += " AND FT_CLIEFOR BETWEEN '" + MV_PAR12 + "' AND '" + MV_PAR14 + "'"
   ElseIf !Empty(MV_PAR12) 
   	_cWhere  += " AND FT_CLIEFOR >= '" + MV_PAR12 + "' "
   EndIf                                                             
   
   //=========================================		
   // Loja Cliente De - Ate
   //=========================================
   If !Empty(MV_PAR15)	
   	_cWhere  += " AND FT_LOJA BETWEEN '" + MV_PAR13 + "' AND '" + MV_PAR15 + "'"
   ElseIf !Empty(MV_PAR13) 
   	_cWhere  += " AND FT_LOJA >= '" + MV_PAR13 + "' "
   EndIf             

   _cOrder :=  " ORDER BY FT_TIPOMOV, FT_ENTRADA, FT_NFISCAL, FT_SERIE, FT_CLIEFOR, FT_LOJA , FT_ITEM "

   _cQry += _cWhere + _cOrder     
     
   If Select("QRYSFT") > 0
      QRYSFT->(DBCloseArea())
   EndIf
   
   _cQry := ChangeQuery(_cQry) 

   MPSysOpenQuery( _cQry,"QRYSFT" )

   TCSetField("QRYSFT", "FT_EMISSAO", "D", 8)
   TCSetField("QRYSFT", "FT_ENTRADA", "D", 8)

   If QRYSFT->(Eof()) .Or. QRYSFT->(Bof())
      _lRet := .F.
   EndIf                 
   
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: RFIS006M
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/04/2017
Descrição---------: Monta o Relatório em Excel tendo como base a query gerada.
Parametros--------: oReport,oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function RFIS006M(oReport As Object,oproc As Object) As Logical
Local  _nI := 0 As Numeric
Local _nTotRegs := 0 As Numeric
Local _cCamposFor := "" As Character
Local _nQtdItens := 0 As Numeric
Local _cListaCFOP := "" As Character
Local _cCfopDev1 := U_ITGETMV( "IT_CFOPDEV1" , "" ) As Character
Local _cCfopDev2 := U_ITGETMV( "IT_CFOPDEV2" , "" ) As Character
Local _aDadosRel := {} As Array
Local _aRegDados := {} As Array
Local _cNomeCampo := "" As Character

Begin Sequence                                                                       
   
   If oReport # NIL
      _lRet:=.T.
      FWMsgRun( , {|| _lRet := RFIS006D()}, "Aguarde!" , 'Gerando Dados do Relatório...' )
      If ! _lRet
         U_ITMsg("Não existem dados para emissão do relatório.","Atenção",,1)
         Break
      EndIf
   EndIf
   
   //================================================================================
   // Conta total de registros a serem processados
   //================================================================================
   DBSelectArea("QRYSFT")
   Count to _nTotRegs                                      

   If _nTotRegs > 10000
      If !U_ITMsg("Serão processado "+AllTrim(Str(_nTotRegs))+" Registros. Deseja Continuar?",'Atenção!',,3,2,2)
         Return .F.
      EndIf
   EndIf

   QRYSFT->(DBGoTop())
                                
   DBSelectArea("TRBREL")
   ZAP
   DBSelectArea("TRBRAT")
   ZAP

   If oReport # NIL
      oReport:SetMeter(_nTotRegs)
      oReport:Section(1):Init()
      oReport:Section(1):PrintLine() 
      oReport:Section(1):Section(1):Init()
   EndIf
   
   nCont:=0   

   _cCamposFor := "D1_TES/CCUSTO/CTT_DESC01/NOME/CNPJ/INSCREST/NUNICIPIO/ESTADO/ARMAZEM/UNIMEDIDA/D1_VALISS/F2_I_CTRA/F2_I_LTRA/F2_I_PLACA/F2_I_FRET/F2_TPFRETE/F4_DUPLIC/F4_ESTOQUE/F4_FINALID/A2_NOME/A2_MUN/A2_EST"
   _cCamposFor += "/F3_CODRSEF/ST_NOME/ST_CGC/ST_INSC/ST_INSCM/ST_CIDCOB/ST__ESTCOB/ED_CODIGO/ED_DESCRIC/A2CALCIRF/A1SIMPNAC/D1_BASEISS/D1_ALIQISS/C7_OBSMREC/"
   
   _aDadosRel := {}
   _aRegDados := {}
   _cFilAntes := ""

   While ! QRYSFT->(Eof())

      TRBREL->(DBAPPEND())

      If oReport # NIL
         oReport:IncMeter()
         nCont++
         oReport:SetMsgPrint("Processando " + StrZero(nCont,7) + " de " + StrZero(_nTotRegs,7))
      Else
         If ValType(oproc) = "O"
            nCont++
            oproc:cCaption := ("Processando " + StrZero(nCont,7) + " de " + StrZero(_nTotRegs,7))
            ProcessMessages()
         EndIf
      EndIf
      
      For _nI := 1 To TRBREL->(FCount())    
         If ! AllTrim(TRBREL->(FieldName(_nI))) $ _cCamposFor // Esta condição exclui os campos que terão os valores atribuidos manualmente.         
            &("TRBREL->"+TRBREL->(FieldName(_nI))) := &("QRYSFT->"+(TRBREL->(FieldName(_nI))))
         ElseIf AllTrim(TRBREL->(FieldName(_nI))) == "C7_OBSMREC" 
            If QRYSFT->C7_OBSMREC > 0
               SC7->(DBGoTo(QRYSFT->C7_OBSMREC))
               TRBREL->C7_OBSMREC := SC7->C7_OBS
            EndIf 
         EndIf
      Next   

      TRBREL->FT_TIPO    := TipoLanc(QRYSFT->FT_TIPO)

      TRBREL->ST_NOME    := QRYSFT->M0_NOME
      TRBREL->ST_CGC     := QRYSFT->M0_CGC
      TRBREL->ST_INSC    := QRYSFT->M0_INSCR
      TRBREL->ST_INSCM   := QRYSFT->M0_INSCRM
      TRBREL->ST_CIDCOB  := QRYSFT->M0_MUN
      TRBREL->ST__ESTCOB := QRYSFT->M0_EST

      TRBREL->F3_CODRSEF := QRYSFT->F3_CODRSEF 

      If Val(AllTrim(QRYSFT->FT_CFOP)) < 5000 // FT_TIPOMOV == 'E' // Pagamento - dados da nota fiscal de entrada  

         _cListaCFOP := _cCfopDev1 + "#" + _cCfopDev2 // Relacao de CFOPs de devolucao consideradas no relatorio de conferencia fiscal.
         //If (! Empty(QRYSFT->FT_NFORI) .And. AllTrim(QRYSFT->FT_CFOP) $ _cListaCFOP ) .Or. (! Empty(QRYSFT->FT_NFORI) .And. RFIS006A(QRYSFT->FT_CLIEFOR))  // .And. So numeros em FT_CLIEFOR
         If QRYSFT->F1_TIPO  $ 'D|B'
            TRBREL->NOME       := QRYSFT->SF1_A1_NOME 
            TRBREL->CNPJ       := QRYSFT->SF1_A1_CGC  
            TRBREL->INSCREST   := QRYSFT->SF1_A1_INSCR 
            TRBREL->NUNICIPIO  := QRYSFT->SF1_A1_MUN 
            TRBREL->ESTADO     := QRYSFT->SF1_A1_EST 
            
            TRBREL->A1SIMPNAC := "" 
            If QRYSFT->SF1_A1_SIMPNAC == "1"
               TRBREL->A1SIMPNAC := "SIM" 
            ElseIf QRYSFT->SF1_A1_SIMPNAC == "2"
               TRBREL->A1SIMPNAC := "NAO"
            EndIf

         Else

            TRBREL->NOME       := QRYSFT->SF1_A2_NOME 
            TRBREL->CNPJ       := QRYSFT->SF1_A2_CGC  
            TRBREL->INSCREST   := QRYSFT->SF1_A2_INSCR 
            TRBREL->NUNICIPIO  := QRYSFT->SF1_A2_MUN 
            TRBREL->ESTADO     := QRYSFT->SF1_A2_EST 
            
            TRBREL->A2CALCIRF := "" 
            If QRYSFT->SF1_A2_CALCIRF == '1' // ;; 
               TRBREL->A2CALCIRF := "NORMAL" // 1=Normal 
            ElseIf QRYSFT->SF1_A2_CALCIRF == '2'
               TRBREL->A2CALCIRF := "IRRF BAIXA" // 2=IRRF Baixa; 
            ElseIf QRYSFT->SF1_A2_CALCIRF == '3'
               TRBREL->A2CALCIRF := "SIMPLES" // 3=Simples
            ElseIf QRYSFT->SF1_A2_CALCIRF == '4'
               TRBREL->A2CALCIRF := "EMPRESA INDIVIDUAL" // 4=Empresa Individual 
            EndIf
         EndIf
         
         If QRYSFT->F3_CODRSEF $ "101|102"
            TRBREL->FT_BASEIPI := 0  // BC IPI	
            TRBREL->FT_ALIQIPI := 0      // ALQ IPI	
            TRBREL->FT_VALIPI  := 0   // VL IPI	
            TRBREL->FT_DESPESA := 0 // DESPESAS	
            TRBREL->FT_FRETE   := 0  // FRETE	
            TRBREL->FT_SEGURO  := 0  // SEGURO	
            TRBREL->FT_PRCUNIT := 0 // VL UNITARIO	
            TRBREL->D1_TES     := "" 
            TRBREL->CCUSTO     := ""
            TRBREL->CTT_DESC01 := ""
            TRBREL->ARMAZEM    := "" 
            TRBREL->UNIMEDIDA  := ""
            TRBREL->D1_BASEISS := 0
            TRBREL->D1_ALIQISS := 0 
            TRBREL->D1_VALISS  := 0 
            TRBREL->F2_I_CTRA  := ""
            TRBREL->F2_I_LTRA  := ""  
            TRBREL->F2_I_PLACA := ""  
            TRBREL->F2_I_FRET  := 0 // Ratear valor do frete pela qtd itens.
            TRBREL->F2_TPFRETE := "" 
            TRBREL->F4_DUPLIC  := ""  
            TRBREL->F4_ESTOQUE := ""
            TRBREL->F4_FINALID := ""  
            TRBREL->C7_NUM     := ""
            TRBREL->C7_OBSMREC := ""
         Else
            //--------------------
            // Entradas :  BC IPI -> D1_BASEIPI
            //               ALQ IPI -> D1_IPI
            //               VL IPI -> D1_VALIPI  
            TRBREL->FT_BASEIPI := QRYSFT->D1_BASEIPI  // BC IPI	
            TRBREL->FT_ALIQIPI := QRYSFT->D1_IPI      // ALQ IPI	
            TRBREL->FT_VALIPI  := QRYSFT->D1_VALIPI   // VL IPI	
            
            //Entradas : DESPESAS -> D1_DESPESA
            //          FRETE -> D1_VALFRE
            //          SEGURO -> D1_SEGURO    
            
            
            TRBREL->FT_DESPESA := QRYSFT->D1_DESPESA // DESPESAS	
            TRBREL->FT_FRETE   := QRYSFT->D1_VALFRE  // FRETE	
            TRBREL->FT_SEGURO  := QRYSFT->D1_SEGURO  // SEGURO	
            TRBREL->FT_PRCUNIT := QRYSFT->D1_VUNIT   // VL UNITARIO // Valor de custo.
            TRBREL->D1_TES     := QRYSFT->D1_TES
            TRBREL->CCUSTO     := QRYSFT->D1_CC
            TRBREL->CTT_DESC01 := QRYSFT->SF1_DESC01 
            TRBREL->ARMAZEM    := QRYSFT->D1_LOCAL
            TRBREL->UNIMEDIDA  := QRYSFT->D1_UM
            //-------------------------------------------
            TRBREL->D1_BASEISS := QRYSFT->D1_BASEISS
            TRBREL->D1_ALIQISS := QRYSFT->D1_ALIQISS
            //-------------------------------------------
            TRBREL->D1_VALISS  := QRYSFT->SF1_VALISS    
            TRBREL->F4_DUPLIC  := QRYSFT->SF1_DUPLIC
            TRBREL->F4_ESTOQUE := QRYSFT->SF1_ESTOQUE
            TRBREL->F4_FINALID := QRYSFT->SF1_FINALID

            TRBREL->ED_CODIGO  := QRYSFT->ED_CODIGO
            TRBREL->ED_DESCRIC := QRYSFT->ED_DESCRIC
         EndIf
      
      
      Else // Recebimento Dados da nota fiscal de saída. // FT_TIPOMOV = 'S'         

         _nQtdItens := QRYSFT->QTD_ITENS 
      
         _cListaCFOP := _cCfopDev1 + "#" + _cCfopDev2 // Relacao de CFOPs de devolucao consideradas no relatorio de conferencia fiscal.
         //If (! Empty(QRYSFT->FT_NFORI) .And. AllTrim(QRYSFT->FT_CFOP) $ _cListaCFOP) .Or. (! Empty(QRYSFT->FT_NFORI) .And. ! RFIS006A(QRYSFT->FT_CLIEFOR))
         If QRYSFT->F2_TIPO  $ 'D|B'
            TRBREL->NOME       := QRYSFT->SF2_A2_NOME 
            TRBREL->CNPJ       := QRYSFT->SF2_A2_CGC  
            TRBREL->INSCREST   := QRYSFT->SF2_A2_INSCR 
            TRBREL->NUNICIPIO  := QRYSFT->SF2_A2_MUN 
            TRBREL->ESTADO     := QRYSFT->SF2_A2_EST 
            
            TRBREL->A2CALCIRF := "" 
            If QRYSFT->SF2_A2_CALCIRF == '1' // ;; 
               TRBREL->A2CALCIRF := "NORMAL" // 1=Normal 
            ElseIf QRYSFT->SF2_A2_CALCIRF == '2'
               TRBREL->A2CALCIRF := "IRRF BAIXA" // 2=IRRF Baixa; 
            ElseIf QRYSFT->SF2_A2_CALCIRF == '3'
               TRBREL->A2CALCIRF := "SIMPLES" // 3=Simples
            ElseIf QRYSFT->SF2_A2_CALCIRF == '4'
               TRBREL->A2CALCIRF := "EMPRESA INDIVIDUAL" // 4=Empresa Individual 
            EndIf

         Else

            TRBREL->NOME       := QRYSFT->SF2_A1_NOME 
            TRBREL->CNPJ       := QRYSFT->SF2_A1_CGC  
            TRBREL->INSCREST   := QRYSFT->SF2_A1_INSCR 
            TRBREL->NUNICIPIO  := QRYSFT->SF2_A1_MUN 
            TRBREL->ESTADO     := QRYSFT->SF2_A1_EST 

            TRBREL->A1SIMPNAC := "" 
            If QRYSFT->SF2_A1_SIMPNAC == "1"
               TRBREL->A1SIMPNAC := "SIM" 
            ElseIf QRYSFT->SF2_A1_SIMPNAC == "2"
               TRBREL->A1SIMPNAC := "NAO"
            EndIf

         EndIf

         If QRYSFT->F3_CODRSEF $ "101|102"//QRYSFT->FT_OBSERV <>"NF CANCELADA                   "   
            
            TRBREL->FT_BASEIPI := 0  // BC IPI	
            TRBREL->FT_ALIQIPI := 0      // ALQ IPI	
            TRBREL->FT_VALIPI  := 0   // VL IPI	
            TRBREL->FT_DESPESA := 0 // DESPESAS	
            TRBREL->FT_FRETE   := 0  // FRETE	
            TRBREL->FT_SEGURO  := 0  // SEGURO	
            TRBREL->FT_PRCUNIT := 0 // VL UNITARIO	
            TRBREL->D1_TES     := "" 
            TRBREL->CCUSTO     := ""
            TRBREL->CTT_DESC01 := ""
            TRBREL->ARMAZEM    := "" 
            TRBREL->UNIMEDIDA  := ""
            TRBREL->D1_BASEISS := 0
            TRBREL->D1_ALIQISS := 0 
            TRBREL->D1_VALISS  := 0 
            TRBREL->F2_I_CTRA  := ""
            TRBREL->F2_I_LTRA  := ""  
            TRBREL->F2_I_PLACA := ""  
            TRBREL->F2_I_FRET  := 0 // Ratear valor do frete pela qtd itens.
            TRBREL->F2_TPFRETE := "" 
            TRBREL->F4_DUPLIC  := ""  
            TRBREL->F4_ESTOQUE := ""
            TRBREL->F4_FINALID := ""  
            TRBREL->C7_NUM     := ""
            TRBREL->C7_OBSMREC := ""
         
         Else   //--------------------
            
            //SAIDAS :  BC IPI -> SD2->D2_BASEIPI
            //          ALQ IPI -> SD2->D2_IPI
            //            VL IPI -> SD2->D2_VALIPI 
           
            TRBREL->FT_BASEIPI := QRYSFT->D2_BASEIPI  // BC IPI	
            TRBREL->FT_ALIQIPI := QRYSFT->D2_IPI      // ALQ IPI	
            TRBREL->FT_VALIPI  := QRYSFT->D2_VALIPI   // VL IPI	
                                                   
            
            //SAIDAS : DESPESAS -> SD2->D2_DESPESA
            //       FRETE -> SD2->D2_VALFRE
            //       SEGURO -> SD2->D2_SEGURO 
            
            TRBREL->FT_DESPESA := QRYSFT->D2_DESPESA // DESPESAS	
            TRBREL->FT_FRETE   := QRYSFT->D2_VALFRE  // FRETE	
            TRBREL->FT_SEGURO  := QRYSFT->D2_SEGURO  // SEGURO	
            TRBREL->FT_PRCUNIT := QRYSFT->D2_PRUNIT // VL UNITARIO	
           
            //--------------------
            TRBREL->D1_TES     := QRYSFT->D2_TES 
            TRBREL->CCUSTO     := QRYSFT->D2_CCUSTO 
            TRBREL->CTT_DESC01 := QRYSFT->SF2_DESC01 

            TRBREL->ARMAZEM    := QRYSFT->D2_LOCAL 
            TRBREL->UNIMEDIDA  := QRYSFT->D2_UM
            TRBREL->D1_BASEISS := QRYSFT->D2_BASEISS
            TRBREL->D1_ALIQISS := QRYSFT->D2_ALIQISS 
            TRBREL->D1_VALISS  := QRYSFT->D2_VALISS 
            TRBREL->F2_I_CTRA  := QRYSFT->F2_I_CTRA  
            TRBREL->F2_I_LTRA  := QRYSFT->F2_I_LTRA  
            TRBREL->F2_I_PLACA := QRYSFT->F2_I_PLACA  
            TRBREL->F2_I_FRET  := QRYSFT->F2_I_FRET / _nQtdItens // Ratear valor do frete pela qtd itens.
            TRBREL->F2_TPFRETE := QRYSFT->F2_TPFRETE 
            TRBREL->F4_DUPLIC  := QRYSFT->SF2_DUPLIC  
            TRBREL->F4_ESTOQUE := QRYSFT->SF2_ESTOQUE  
            TRBREL->F4_FINALID := QRYSFT->SF2_FINALID  

            TRBREL->C7_NUM  := QRYSFT->C7_NUM

            If QRYSFT->C7_OBSMREC > 0
               SC7->(DBGoTo(QRYSFT->C7_OBSMREC))

               TRBREL->C7_OBSMREC := SC7->C7_OBS
            EndIf 

         EndIf

         If !Empty(QRYSFT->F2_I_CTRA) 
            TRBREL->A2_NOME    := QRYSFT->SF2T_A2_NOME    
            TRBREL->A2_MUN     := QRYSFT->SF2T_A2_MUN     
            TRBREL->A2_EST     := QRYSFT->SF2T_A2_EST              
         EndIf
      EndIf
      
      If oReport # NIL
         oReport:Section(1):Section(1):PrintLine() 
      Else
      
         _aRegDados := {}
         
         For _nI := 1 To Len(_aCampos)
            _cNomeCampo := "TRBREL->"+_aCampos[_nI]
             
            _nJ := aScan(_aStrucRel, {|x| x[1] =AllTrim(_aCampos[_nI])} )
            If _nJ > 0 .And. _aStrucRel[_nJ,2] == "C"
               If SubStr(AllTrim(&(_cNomeCampo)),1,1) $ "0123456789"
                  aAdd(_aRegDados, CHR(160)+&(_cNomeCampo) )
               Else
                  aAdd(_aRegDados, &(_cNomeCampo) )
               EndIf
            Else
               aAdd(_aRegDados, &(_cNomeCampo) )
            EndIf
         Next
         
         aAdd(_aDadosRel, _aRegDados)
      EndIf

      TRBREL->(MSUnLock())

      QRYSFT->(DBSkip())

   EndDo
   

If oReport # NIL
   oReport:Section(1):SetPageBreak(.T.)
   oReport:Section(1):Finish()
   oReport:Section(1):Section(1):Finish()
Else
   //================================================================================
   // Abrindo o relatório no Excel.
   //================================================================================

   oproc:cCaption := ("Exportando para excel...")

   _cDir := GetTempPath() 
   _cArq := "RFIS006_"+StrTran(DToC(Date()),"/","-")+"_"+StrTran(Time(),":","_")+".xlsx"
   //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX,oProc)
   U_ITGEREXCEL(_cArq,_cDir  ,"RELATORIO DE CONFERENCIA FISCAL" ,          ,_aCabExcel ,_aDadosRel,           ,          ,       , .T.        ,            ,          , .F.        ,.T.,oproc)

    //Tentando abrir o objeto
   nRet := ShellExecute("open", _cArq, "", _cDir, 1)
     
   //Se houver algum erro
   If nRet <= 32
      MsgStop("Não foi possível abrir o arquivo " +_cDir+_cArq+ "!", "Atenção")
   EndIf 

EndIf

End Sequence

Return



/*
===============================================================================================================================
Programa----------: RFIS006A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2017
Descrição---------: Verifica se em uma string possui apenas numueros ou existe letras com numeros.
Parametros--------: _cCampo = Contúdo a ser verificado.
Retorno-----------: .T. = Existe apenas numeros no conteúdo. ou .F. = Existe pelo menos uma letra no contéudo de _cCampo.
===============================================================================================================================
*/  
Static Function RFIS006A(_cCampo)

Local _lRet := .T.
Local _aDados, _nI 

Begin Sequence
   _cCampo := AllTrim(_cCampo)    
   _aDados := {}
   For _nI:= 1 to Len(_cCampo)
      aAdd(_aDados,SubStr(_cCampo,_nI,1))
   Next
                      
   For _nI:= 1 to Len(_aDados)
      If ! _aDados[_nI] $ "1234567890"
         _lRet := .F. // Existe pelo menos uma letra em _cCampo.
      EndIf        
   Next

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: RFIS006Trab
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2017
Descrição---------: Verifica se em uma string possui apenas numueros ou existe letras com numeros.
Parametros--------: _cCampo = Contúdo a ser verificado.
Retorno-----------: .T. = Existe apenas numeros no conteúdo. ou .F. = Existe pelo menos uma letra no contéudo de _cCampo.
===============================================================================================================================
*/  
Static Function RFIS006Trab()

Local  _aStrucRat := {}
   
   _aStrucRel := {}
   aAdd(_aStrucRel,{"FT_FILIAL" ,TamSX3("FT_FILIAL")[3],TamSX3("FT_FILIAL")[1],TamSX3("FT_FILIAL")[2]})  // CODIGO
   aAdd(_aStrucRel,{"ST_NOME"   ,"C",60,0})	// RAZAO SOCIAL
   aAdd(_aStrucRel,{"ST_CGC"    ,"C",14,0}) // CNPJ	
   aAdd(_aStrucRel,{"ST_INSC"   ,"C",12,0}) // IE
   aAdd(_aStrucRel,{"ST_INSCM"  ,"C",15,0}) // IM	
   aAdd(_aStrucRel,{"ST_CIDCOB" ,"C",50,0}) // CIDADE	
   aAdd(_aStrucRel,{"ST__ESTCOB","C",2,0})  // UF	
   aAdd(_aStrucRel,{"FT_EMISSAO",TamSX3("FT_EMISSAO")[3],TamSX3("FT_EMISSAO")[1],TamSX3("FT_EMISSAO")[2]}) // DATA EMISSÃO	 
   aAdd(_aStrucRel,{"FT_ENTRADA",TamSX3("FT_ENTRADA")[3],TamSX3("FT_ENTRADA")[1],TamSX3("FT_ENTRADA")[2]}) // DATA ENT/SAI	
   aAdd(_aStrucRel,{"FT_NFISCAL",TamSX3("FT_NFISCAL")[3],TamSX3("FT_NFISCAL")[1],TamSX3("FT_NFISCAL")[2]}) // NÚMERO	
   aAdd(_aStrucRel,{"FT_SERIE"  ,TamSX3("FT_SERIE")[3]  ,TamSX3("FT_SERIE")[1]  ,TamSX3("FT_SERIE")[2]})   // SÉRIE	
   aAdd(_aStrucRel,{"FT_ESPECIE",TamSX3("FT_ESPECIE")[3],TamSX3("FT_ESPECIE")[1],TamSX3("FT_ESPECIE")[2]}) // MODELO	
   aAdd(_aStrucRel,{"FT_CHVNFE" ,TamSX3("FT_CHVNFE")[3] ,TamSX3("FT_CHVNFE")[1] ,TamSX3("FT_CHVNFE")[2]})  // CHAVE DE ACESSO	
   aAdd(_aStrucRel,{"F3_CODRSEF",TamSX3("F3_CODRSEF")[3],TamSX3("F3_CODRSEF")[1],TamSX3("F3_CODRSEF")[2]}) // SITUAÇÃO	
   aAdd(_aStrucRel,{"FT_TIPOMOV",TamSX3("FT_TIPOMOV")[3],TamSX3("FT_TIPOMOV")[1],TamSX3("FT_TIPOMOV")[2]}) // TIPO MOV	
   aAdd(_aStrucRel,{"FT_TIPO"   ,"C"                    ,20                     ,0                      }) // TIPO LANC	
   aAdd(_aStrucRel,{"D1_TES"    ,TamSX3("D1_TES")[3]    ,TamSX3("D1_TES")[1]    ,TamSX3("D1_TES")[2]})     // COD. TES	
   aAdd(_aStrucRel,{"F4_FINALID",TamSX3("F4_FINALID")[3],TamSX3("F4_FINALID")[1],TamSX3("F4_FINALID")[2]}) // DESCRIÇÃO TES	
   aAdd(_aStrucRel,{"FT_CFOP"   ,TamSX3("FT_CFOP")[3]   ,TamSX3("FT_CFOP")[1]   ,TamSX3("FT_CFOP")[2]})    // 	CFOP	

   aAdd(_aStrucRel,{"ED_CODIGO"   ,TamSX3("ED_CODIGO")[3]   ,TamSX3("ED_CODIGO")[1]   ,TamSX3("ED_CODIGO")[2]})    // 	NATUREZA DE OPERAÇÃO
   aAdd(_aStrucRel,{"ED_DESCRIC"   ,TamSX3("ED_DESCRIC")[3]   ,TamSX3("ED_DESCRIC")[1]   ,TamSX3("ED_DESCRIC")[2]})    // 	DESCRIÇÃO NATUREZA

   aAdd(_aStrucRel,{"FT_NFORI"  ,TamSX3("FT_NFORI")[3]  ,TamSX3("FT_NFORI")[1]  ,TamSX3("FT_NFORI")[2]})   // 	NÚMERO NOTA ORIGEM	
   aAdd(_aStrucRel,{"FT_SERORI" ,TamSX3("FT_SERORI")[3] ,TamSX3("FT_SERORI")[1] ,TamSX3("FT_SERORI")[2]})  // 	SÉRIE NOTA DE ORIGEM	
   aAdd(_aStrucRel,{"CCUSTO"    ,TamSX3("D1_CC")[3]     ,TamSX3("D1_CC")[1]     ,TamSX3("D1_CC")[2]})      // COD. CENTRO DE CUSTO	
   aAdd(_aStrucRel,{"CTT_DESC01",TamSX3("CTT_DESC01")[3],TamSX3("CTT_DESC01")[1],TamSX3("CTT_DESC01")[2]}) //  DESCRIÇÃO DO CENTRO DE CUSTO	
   aAdd(_aStrucRel,{"FT_CLIEFOR",TamSX3("FT_CLIEFOR")[3],TamSX3("FT_CLIEFOR")[1],TamSX3("FT_CLIEFOR")[2]}) // 	COD. CLIENTE/FORN	
   aAdd(_aStrucRel,{"FT_LOJA"   ,TamSX3("FT_LOJA")[3]   ,TamSX3("FT_LOJA")[1]   ,TamSX3("FT_LOJA")[2]})    //  LOJA CLIENTE/FORN	
   aAdd(_aStrucRel,{"NOME"      ,TamSX3("A1_NOME")[3]   ,TamSX3("A1_NOME")[1]   ,TamSX3("A1_NOME")[2]})    // 	RAZAO SOCIAL CLIENTE/FORN	
   aAdd(_aStrucRel,{"CNPJ"      ,TamSX3("A1_CGC")[3]    ,TamSX3("A1_CGC")[1]    ,TamSX3("A1_CGC")[2]})     // 	CNPJ OU CPF CLIENTE/FORN	
   aAdd(_aStrucRel,{"INSCREST"  ,TamSX3("A1_INSCR")[3]  ,TamSX3("A1_INSCR")[1]  ,TamSX3("A1_INSCR")[2]})   // IE CLIENTE/FORN	
   aAdd(_aStrucRel,{"NUNICIPIO" ,TamSX3("A1_MUN")[3]    ,TamSX3("A1_MUN")[1]    ,TamSX3("A1_MUN")[2]})     // CIDADE 	
   aAdd(_aStrucRel,{"ESTADO"    ,TamSX3("A1_EST")[3]    ,TamSX3("A1_EST")[1]    ,TamSX3("A1_EST")[2]})     // UF	
   
   aAdd(_aStrucRel,{"A2CALCIRF","C"    ,20    ,0})    // Calcula IRRF	
   aAdd(_aStrucRel,{"A1SIMPNAC","C"    ,3   ,0})     // Optante do Simples Nacional
 
   aAdd(_aStrucRel,{"ARMAZEM"   ,TamSX3("D1_LOCAL")[3]  ,TamSX3("D1_LOCAL")[1]  ,TamSX3("D1_LOCAL")[2]})   // ARMAZÉM/DEPÓSITO	
   aAdd(_aStrucRel,{"B1_GRUPO"  ,TamSX3("B1_GRUPO")[3]  ,TamSX3("B1_GRUPO")[1]  ,TamSX3("B1_GRUPO")[2]})   // COD GRUPO DE PRODUTO	
   aAdd(_aStrucRel,{"BM_DESC"   ,TamSX3("BM_DESC")[3]   ,TamSX3("BM_DESC")[1]   ,TamSX3("BM_DESC")[2]})    // DESCRICAO GRUPO PRODUTO	
   aAdd(_aStrucRel,{"FT_PRODUTO",TamSX3("FT_PRODUTO")[3],TamSX3("FT_PRODUTO")[1],TamSX3("FT_PRODUTO")[2]}) // COD. PRODUTO	
   aAdd(_aStrucRel,{"B1_DESC"   ,TamSX3("B1_DESC")[3]   ,TamSX3("B1_DESC")[1]   ,TamSX3("B1_DESC")[2]})    // DESCRICAO PRODUTO	
   aAdd(_aStrucRel,{"FT_POSIPI" ,TamSX3("FT_POSIPI")[3] ,TamSX3("FT_POSIPI")[1] ,TamSX3("FT_POSIPI")[2]})  // NCM	
   aAdd(_aStrucRel,{"UNIMEDIDA" ,TamSX3("D1_UM")[3]     ,TamSX3("D1_UM")[1]     ,TamSX3("D1_UM")[2]})      // UNIDADE DE MEDIDA	
   aAdd(_aStrucRel,{"FT_QUANT"  ,TamSX3("FT_QUANT")[3]  ,TamSX3("FT_QUANT")[1]  ,TamSX3("FT_QUANT")[2]})   // QUANTIDADE	
   aAdd(_aStrucRel,{"FT_PRCUNIT",TamSX3("FT_PRCUNIT")[3],TamSX3("FT_PRCUNIT")[1],TamSX3("FT_PRCUNIT")[2]}) // VL UNITARIO	
   aAdd(_aStrucRel,{"FT_DESCONT",TamSX3("FT_DESCONT")[3],TamSX3("FT_DESCONT")[1],TamSX3("FT_DESCONT")[2]}) // VL DESCONTO	
   aAdd(_aStrucRel,{"FT_DESPESA",TamSX3("FT_DESPESA")[3],TamSX3("FT_DESPESA")[1],TamSX3("FT_DESPESA")[2]}) // DESPESAS	
   aAdd(_aStrucRel,{"FT_FRETE"  ,TamSX3("FT_FRETE")[3]  ,TamSX3("FT_FRETE")[1]  ,TamSX3("FT_FRETE")[2]})   // FRETE	
   aAdd(_aStrucRel,{"FT_SEGURO" ,TamSX3("FT_SEGURO")[3] ,TamSX3("FT_SEGURO")[1] ,TamSX3("FT_SEGURO")[2]})  // SEGURO	
   aAdd(_aStrucRel,{"FT_TOTAL"  ,TamSX3("FT_TOTAL")[3]  ,TamSX3("FT_TOTAL")[1]  ,TamSX3("FT_TOTAL")[2]})   // VL TOTAL ITEM	
   aAdd(_aStrucRel,{"FT_VALCONT",TamSX3("FT_VALCONT")[3],TamSX3("FT_VALCONT")[1],TamSX3("FT_VALCONT")[2]}) // VL TOTAL NF	
   aAdd(_aStrucRel,{"FT_CLASFIS",TamSX3("FT_CLASFIS")[3],TamSX3("FT_CLASFIS")[1],TamSX3("FT_CLASFIS")[2]}) // CST ICMS	
   aAdd(_aStrucRel,{"FT_BASEICM",TamSX3("FT_BASEICM")[3],TamSX3("FT_BASEICM")[1],TamSX3("FT_BASEICM")[2]}) // BC ICMS	
   aAdd(_aStrucRel,{"FT_ALIQICM",TamSX3("FT_ALIQICM")[3],TamSX3("FT_ALIQICM")[1],TamSX3("FT_ALIQICM")[2]}) // ALQ ICMS	
   aAdd(_aStrucRel,{"FT_VALICM" ,TamSX3("FT_VALICM")[3] ,TamSX3("FT_VALICM")[1] ,TamSX3("FT_VALICM")[2]})  // VL ICMS
   aAdd(_aStrucRel,{"FT_VALANTI",TamSX3("FT_VALANTI")[3],TamSX3("FT_VALANTI")[1],TamSX3("FT_VALANTI")[2]}) // ICMS ANTECIPADO  
   aAdd(_aStrucRel,{"FT_BASERET",TamSX3("FT_BASERET")[3],TamSX3("FT_BASERET")[1],TamSX3("FT_BASERET")[2]}) // BC ICMS ST	
   aAdd(_aStrucRel,{"FT_ALIQSOL",TamSX3("FT_ALIQSOL")[3],TamSX3("FT_ALIQSOL")[1],TamSX3("FT_ALIQSOL")[2]}) // ALQ ST	
   aAdd(_aStrucRel,{"FT_MARGEM" ,TamSX3("FT_MARGEM")[3] ,TamSX3("FT_MARGEM")[1] ,TamSX3("FT_MARGEM")[2]})  // MVA ST	   
   aAdd(_aStrucRel,{"FT_ICMSRET",TamSX3("FT_ICMSRET")[3],TamSX3("FT_ICMSRET")[1],TamSX3("FT_ICMSRET")[2]}) // VL ICMS ST	
   aAdd(_aStrucRel,{"FT_BASEDES",TamSX3("FT_BASEDES")[3],TamSX3("FT_BASEDES")[1],TamSX3("FT_BASEDES")[2]}) // BASE DIFAL	
   aAdd(_aStrucRel,{"FT_ICMSCOM",TamSX3("FT_ICMSCOM")[3],TamSX3("FT_ICMSCOM")[1],TamSX3("FT_ICMSCOM")[2]}) // VL ICMS DIFAL	
   aAdd(_aStrucRel,{"FT_CTIPI"  ,TamSX3("FT_CTIPI")[3]  ,TamSX3("FT_CTIPI")[1]  ,TamSX3("FT_CTIPI")[2]})   // CST IPI	
   aAdd(_aStrucRel,{"FT_BASEIPI",TamSX3("FT_BASEIPI")[3],TamSX3("FT_BASEIPI")[1],TamSX3("FT_BASEIPI")[2]}) // BC IPI	
   aAdd(_aStrucRel,{"FT_ALIQIPI",TamSX3("FT_ALIQIPI")[3],TamSX3("FT_ALIQIPI")[1],TamSX3("FT_ALIQIPI")[2]}) // ALQ IPI	
   aAdd(_aStrucRel,{"FT_VALIPI" ,TamSX3("FT_VALIPI")[3] ,TamSX3("FT_VALIPI")[1] ,TamSX3("FT_VALIPI")[2]})  // VL IPI	
   aAdd(_aStrucRel,{"FT_CSTPIS" ,TamSX3("FT_CSTPIS")[3] ,TamSX3("FT_CSTPIS")[1] ,TamSX3("FT_CSTPIS")[2]})  // CST PIS	
   aAdd(_aStrucRel,{"FT_BASEPIS",TamSX3("FT_BASEPIS")[3],TamSX3("FT_BASEPIS")[1],TamSX3("FT_BASEPIS")[2]}) // BC PIS	
   aAdd(_aStrucRel,{"FT_ALIQPIS",TamSX3("FT_ALIQPIS")[3],TamSX3("FT_ALIQPIS")[1],TamSX3("FT_ALIQPIS")[2]}) // ALQ PIS	
   aAdd(_aStrucRel,{"FT_VALPIS" ,TamSX3("FT_VALPIS")[3] ,TamSX3("FT_VALPIS")[1] ,TamSX3("FT_VALPIS")[2]})  // VL PIS	
   aAdd(_aStrucRel,{"FT_CSTCOF" ,TamSX3("FT_CSTCOF")[3] ,TamSX3("FT_CSTCOF")[1] ,TamSX3("FT_CSTCOF")[2]})  // CST COFINS	
   aAdd(_aStrucRel,{"FT_BASECOF",TamSX3("FT_BASECOF")[3],TamSX3("FT_BASECOF")[1],TamSX3("FT_BASECOF")[2]}) // BC COFINS	
   aAdd(_aStrucRel,{"FT_ALIQCOF",TamSX3("FT_ALIQCOF")[3],TamSX3("FT_ALIQCOF")[1],TamSX3("FT_ALIQCOF")[2]}) // ALQ COFINS	
   aAdd(_aStrucRel,{"FT_VALCOF" ,TamSX3("FT_VALCOF")[3] ,TamSX3("FT_VALCOF")[1] ,TamSX3("FT_VALCOF")[2]})  // VL COFINS	
   aAdd(_aStrucRel,{"FT_VALIRR" ,TamSX3("FT_VALIRR")[3] ,TamSX3("FT_VALIRR")[1] ,TamSX3("FT_VALIRR")[2]})  // VL IRRF	
   aAdd(_aStrucRel,{"FT_VALINS" ,TamSX3("FT_VALINS")[3] ,TamSX3("FT_VALINS")[1] ,TamSX3("FT_VALINS")[2]})  // VL INSS	
   aAdd(_aStrucRel,{"FT_VRETCSL",TamSX3("FT_VRETCSL")[3],TamSX3("FT_VRETCSL")[1],TamSX3("FT_VRETCSL")[2]}) // VL CSSL RET	
   aAdd(_aStrucRel,{"FT_VRETPIS",TamSX3("FT_VRETPIS")[3],TamSX3("FT_VRETPIS")[1],TamSX3("FT_VRETPIS")[2]}) // VL PIS RET	
   aAdd(_aStrucRel,{"FT_VRETCOF",TamSX3("FT_VRETCOF")[3],TamSX3("FT_VRETCOF")[1],TamSX3("FT_VRETCOF")[2]}) // VL COFINS RET	
//---------------------------------------------------------------------------------------------------------------
   aAdd(_aStrucRel,{"D1_BASEISS",TamSX3("D1_BASEISS")[3],TamSX3("D1_BASEISS")[1],TamSX3("D1_BASEISS")[2]}) // Base ISS RET	
   aAdd(_aStrucRel,{"D1_ALIQISS",TamSX3("D1_ALIQISS")[3],TamSX3("D1_ALIQISS")[1],TamSX3("D1_ALIQISS")[2]}) // Aliquota ISS RET	
//---------------------------------------------------------------------------------------------------------------
   aAdd(_aStrucRel,{"D1_VALISS" ,TamSX3("D1_VALISS")[3] ,TamSX3("D1_VALISS")[1] ,TamSX3("D1_VALISS")[2]})  // VL ISS RET	
   aAdd(_aStrucRel,{"FT_VALFUM" ,TamSX3("FT_VALFUM")[3] ,TamSX3("FT_VALFUM")[1] ,TamSX3("FT_VALFUM")[2]})  // VL FUNRURAL RET	
   aAdd(_aStrucRel,{"FT_VLSENAR",TamSX3("FT_VLSENAR")[3],TamSX3("FT_VLSENAR")[1],TamSX3("FT_VLSENAR")[2]}) // VL SENAR RET	
   aAdd(_aStrucRel,{"FT_VALFUND",TamSX3("FT_VALFUND")[3],TamSX3("FT_VALFUND")[1],TamSX3("FT_VALFUND")[2]}) // VL FUNDESA RET	
   aAdd(_aStrucRel,{"F2_I_CTRA" ,TamSX3("F2_I_CTRA")[3] ,TamSX3("F2_I_CTRA")[1] ,TamSX3("F2_I_CTRA")[2]})  // COD TRANSPORTADOR	
   aAdd(_aStrucRel,{"F2_I_LTRA" ,TamSX3("F2_I_LTRA")[3] ,TamSX3("F2_I_LTRA")[1] ,TamSX3("F2_I_LTRA")[2]})  // LOJA TRANSPORTADOR	
   aAdd(_aStrucRel,{"A2_NOME"   ,TamSX3("A2_NOME")[3]   ,TamSX3("A2_NOME")[1]   ,TamSX3("A2_NOME")[2]})    // RAZAO SOCIAL TRANSPORTADOR	
   aAdd(_aStrucRel,{"A2_MUN"    ,TamSX3("A2_MUN")[3]    ,TamSX3("A2_MUN")[1]    ,TamSX3("A2_MUN")[2]})     // CIDADE	
   aAdd(_aStrucRel,{"A2_EST"    ,TamSX3("A2_EST")[3]    ,TamSX3("A2_EST")[1]    ,TamSX3("A2_EST")[2]})     // UF TRANSP	
   aAdd(_aStrucRel,{"F2_I_PLACA",TamSX3("F2_I_PLACA")[3],TamSX3("F2_I_PLACA")[1],TamSX3("F2_I_PLACA")[2]}) // PLACA	 			 	 		 		 	 	 	 	 	 	 	 	 	 	 			 		 	 		  		
   aAdd(_aStrucRel,{"F2_I_FRET" ,TamSX3("F2_I_FRET")[3] ,TamSX3("F2_I_FRET")[1] ,TamSX3("F2_I_FRET")[2]})  // VL FRETE	
   aAdd(_aStrucRel,{"F2_TPFRETE",TamSX3("F2_TPFRETE")[3],TamSX3("F2_TPFRETE")[1],TamSX3("F2_TPFRETE")[2]}) // TIPO FRETE	
   aAdd(_aStrucRel,{"F4_DUPLIC" ,TamSX3("F4_DUPLIC")[3] ,TamSX3("F4_DUPLIC")[1] ,TamSX3("F4_DUPLIC")[2]})  // FINANCEIRO	
   aAdd(_aStrucRel,{"F4_ESTOQUE",TamSX3("F4_ESTOQUE")[3],TamSX3("F4_ESTOQUE")[1],TamSX3("F4_ESTOQUE")[2]}) // ESTOQUE 
//-----------------------
   aAdd(_aStrucRel,{"C7_NUM"    ,TamSX3("C7_NUM")[3]    ,TamSX3("C7_NUM")[1]    ,TamSX3("C7_NUM")[2]})     // PEDIDO COMPRAS 
   aAdd(_aStrucRel,{"C7_OBSMREC",TamSX3("C7_OBS")[3]    ,TamSX3("C7_OBS")[1]    ,TamSX3("C7_OBS")[2]})     // OBSERVAÇÃO PEDIDO COMPRAS 
//-----------------------
      
   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   If Select("TRBREL") > 0
      TRBREL->( DBCloseArea() )
   EndIf
    
   _otemp := FWTemporaryTable():New( "TRBREL", _aStrucRel )

   _otemp:AddIndex( "01", {"FT_TIPOMOV","FT_ENTRADA","FT_NFISCAL","FT_SERIE","FT_LOJA"} )
 
   _otemp:Create()
     
   //================================================================================
   // Cria tabela temporária utilizada no rateio de frete.
   //================================================================================   
   _aStrucRat := {}                                
   aAdd(_aStrucRat,{"FT_FILIAL" ,TamSX3("FT_FILIAL")[3],TamSX3("FT_FILIAL")[1],TamSX3("FT_FILIAL")[2]})    // Código da Filial     
   aAdd(_aStrucRat,{"FT_CLIEFOR",TamSX3("FT_CLIEFOR")[3],TamSX3("FT_CLIEFOR")[1],TamSX3("FT_CLIEFOR")[2]}) // COD. CLIENTE/FORN	
   aAdd(_aStrucRat,{"FT_LOJA"   ,TamSX3("FT_LOJA")[3]   ,TamSX3("FT_LOJA")[1]   ,TamSX3("FT_LOJA")[2]})    // LOJA CLIENTE/FORN	
   aAdd(_aStrucRat,{"FT_NFISCAL",TamSX3("FT_NFISCAL")[3],TamSX3("FT_NFISCAL")[1],TamSX3("FT_NFISCAL")[2]}) // NÚMERO	    
   aAdd(_aStrucRat,{"FT_SERIE"  ,TamSX3("FT_SERIE")[3]  ,TamSX3("FT_SERIE")[1]  ,TamSX3("FT_SERIE")[2]})   // SÉRIE	
   aAdd(_aStrucRat,{"QTDITENS"  ,"N"                    ,5                      , 0})   // Quantidade de itens na Nota	
 
   If Select("TRBRAT") > 0
      TRBRAT->( DBCloseArea() )
   EndIf
    
   _otemp := FWTemporaryTable():New( "TRBRAT", _aStrucRat )

   _otemp:AddIndex( "01", {"FT_FILIAL","FT_NFISCAL","FT_SERIE","FT_CLIEFOR","FT_LOJA"} )
 
   _otemp:Create()
                                           
   //================================================================================
   // Montando Cabeçalho do Relatório
   //================================================================================         
   _aCabecalho:={}
   //                Titulo das Colunas             ,Alinhamento ,Formatação, Totaliza?
   aAdd(_aCabecalho,{"CODIGO"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"RAZAO SOCIAL"                 ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CNPJ	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"IE"                           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"IM	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CIDADE	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"UF	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DATA EMISSÃO	 "              ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DATA ENT/SAI	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"NÚMERO	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"SÉRIE	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"MODELO	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CHAVE DE ACESSO	"           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"SITUAÇÃO	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"TIPO	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"TIPO	LANC"                     ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"COD. TES	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESCRIÇÃO TES	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CFOP	"                       ,1           ,1         ,.F.})

   aAdd(_aCabecalho,{"NATUREZA DE OPERAÇÃO"        ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESCRIÇÃO NATUREZA"          ,1           ,1         ,.F.})

   aAdd(_aCabecalho,{"NÚMERO NOTA ORIGEM	"       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"SÉRIE NOTA DE ORIGEM	"       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"COD. CENTRO DE CUSTO	"       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESCRIÇÃO DO CENTRO DE CUSTO" ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"COD. CLIENTE/FORN	"           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"LOJA CLIENTE/FORN	"           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"RAZAO SOCIAL CLIENTE/FORN	"   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CNPJ OU CPF CLIENTE/FORN	"   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"IE CLIENTE/FORN	"            ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CIDADE 	"                     ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"UF	"                        ,1           ,1         ,.F.})

   aAdd(_aCabecalho,{"CÁLCULO IRRF"                 ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"OPT.SIMPLES NACIONAL"         ,1           ,1         ,.F.})

   aAdd(_aCabecalho,{"ARMAZÉM/DEPÓSITO	"           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"COD GRUPO DE PRODUTO	"       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESCRICAO GRUPO PRODUTO	"   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"COD. PRODUTO	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESCRICAO PRODUTO	"           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"NCM	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"UNIDADE DE MEDIDA	"           ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"QUANTIDADE	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL UNITARIO	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL DESCONTO	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"DESPESAS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"FRETE	"                       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"SEGURO	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL TOTAL ITEM	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL TOTAL NF	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CST ICMS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"BC ICMS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ALQ ICMS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL ICMS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ICMS ANTECIPADO"              ,1           ,1         ,.F.})  
   aAdd(_aCabecalho,{"BC ICMS ST	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ALQ ST	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"MVA ST	   "                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL ICMS ST	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"BASE DIFAL	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL ICMS DIFAL	"               ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CST IPI	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"BC IPI	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ALQ IPI	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL IPI	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CST PIS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"BC PIS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ALQ PIS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL PIS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CST COFINS	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"BC COFINS	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ALQ COFINS	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL COFINS	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL IRRF	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL INSS	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL CSSL RET	"             ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL PIS RET	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL COFINS RET	"             ,1           ,1         ,.F.})
//-------------------------------------------------------------------------------------
   aAdd(_aCabecalho,{"BASE ISS RET	"             ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ALQ ISS RET	"             ,1           ,1         ,.F.})
//-------------------------------------------------------------------------------------
   aAdd(_aCabecalho,{"VL ISS RET	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL FUNRURAL RET	"          ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL SENAR RET	"             ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL FUNDESA RET	"          ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"COD TRANSPORTADOR	"       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"LOJA TRANSPORTADOR	"       ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"RAZAO SOCIAL TRANSPORTADOR" ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"CIDADE	"                   ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"UF TRANSP	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"PLACA"                      ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"VL FRETE	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"TIPO FRETE	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"FINANCEIRO	"                ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"ESTOQUE 	 		"          ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"PEDIDO DE COMPRAS"          ,1           ,1         ,.F.})
   aAdd(_aCabecalho,{"OBSERVAÇÃO PEDIDO COMPRAS"  ,1           ,1         ,.F.})
   //======================================================================================================================
   // Array com os campos para leitura de dados e montagem dos dados do relatório.
   //======================================================================================================================
   _aCampos   :={}
   aAdd(_aCampos,"FT_FILIAL")    // CODIGO
   aAdd(_aCampos,"ST_NOME") 	 // RAZAO SOCIAL
   aAdd(_aCampos,"ST_CGC")       // CNPJ	
   aAdd(_aCampos,"ST_INSC")      // IE
   aAdd(_aCampos,"ST_INSCM")     // IM	
   aAdd(_aCampos,"ST_CIDCOB")    // CIDADE	
   aAdd(_aCampos,"ST__ESTCOB")   // UF	
   aAdd(_aCampos,"FT_EMISSAO")   // DATA EMISSÃO	 
   aAdd(_aCampos,"FT_ENTRADA")   // DATA ENT/SAI	
   aAdd(_aCampos,"FT_NFISCAL")   // NÚMERO	
   aAdd(_aCampos,"FT_SERIE")     // SÉRIE	
   aAdd(_aCampos,"FT_ESPECIE")   // MODELO	
   aAdd(_aCampos,"FT_CHVNFE")    // CHAVE DE ACESSO	
   aAdd(_aCampos,"F3_CODRSEF")   // SITUAÇÃO	
   aAdd(_aCampos,"FT_TIPOMOV")   // TIPO MOV
   aAdd(_aCampos,"FT_TIPO "  )   // TIPO LANC
   aAdd(_aCampos,"D1_TES")       // COD. TES	
   aAdd(_aCampos,"F4_FINALID")   // DESCRIÇÃO TES	
   aAdd(_aCampos,"FT_CFOP")      // CFOP	

   aAdd(_aCampos,"ED_CODIGO")    // NATUREZA DE OPERAÇÃO	
   aAdd(_aCampos,"ED_DESCRIC")   // DESCRIÇÃO NATUREZA

   aAdd(_aCampos,"FT_NFORI")     // NÚMERO NOTA ORIGEM	
   aAdd(_aCampos,"FT_SERORI")    // SÉRIE NOTA DE ORIGEM	
   aAdd(_aCampos,"CCUSTO")       // COD. CENTRO DE CUSTO	
   aAdd(_aCampos,"CTT_DESC01")   // DESCRIÇÃO DO CENTRO DE CUSTO	
   aAdd(_aCampos,"FT_CLIEFOR")   // COD. CLIENTE/FORN	
   aAdd(_aCampos,"FT_LOJA")      // LOJA CLIENTE/FORN	
   aAdd(_aCampos,"NOME")         // RAZAO SOCIAL CLIENTE/FORN	
   aAdd(_aCampos,"CNPJ")         // CNPJ OU CPF CLIENTE/FORN	
   aAdd(_aCampos,"INSCREST")     // IE CLIENTE/FORN	
   aAdd(_aCampos,"NUNICIPIO")    // CIDADE 	
   aAdd(_aCampos,"ESTADO")       // UF	

   aAdd(_aCampos,"A2CALCIRF")   // CÁLCULO IRRF
   aAdd(_aCampos,"A1SIMPNAC")   // OPT.SIMPLES NACIONAL

   aAdd(_aCampos,"ARMAZEM")      // ARMAZÉM/DEPÓSITO	
   aAdd(_aCampos,"B1_GRUPO")     // COD GRUPO DE PRODUTO	
   aAdd(_aCampos,"BM_DESC")      // DESCRICAO GRUPO PRODUTO	
   aAdd(_aCampos,"FT_PRODUTO")   // COD. PRODUTO	
   aAdd(_aCampos,"B1_DESC")      // DESCRICAO PRODUTO	
   aAdd(_aCampos,"FT_POSIPI")    // NCM	
   aAdd(_aCampos,"UNIMEDIDA")    // UNIDADE DE MEDIDA	
   aAdd(_aCampos,"FT_QUANT")     // QUANTIDADE	
   aAdd(_aCampos,"FT_PRCUNIT")   // VL UNITARIO	
   aAdd(_aCampos,"FT_DESCONT")   // VL DESCONTO	
   aAdd(_aCampos,"FT_DESPESA")   // DESPESAS	
   aAdd(_aCampos,"FT_FRETE")     // FRETE	
   aAdd(_aCampos,"FT_SEGURO")    // SEGURO	
   aAdd(_aCampos,"FT_TOTAL")     // VL TOTAL ITEM	
   aAdd(_aCampos,"FT_VALCONT")   // VL TOTAL NF	
   aAdd(_aCampos,"FT_CLASFIS")   // CST ICMS	
   aAdd(_aCampos,"FT_BASEICM")   // BC ICMS	
   aAdd(_aCampos,"FT_ALIQICM")   // ALQ ICMS	
   aAdd(_aCampos,"FT_VALICM")    // VL ICMS	
   aAdd(_aCampos,"FT_VALANTI")   // ICMS ANTECIPADO  
   aAdd(_aCampos,"FT_BASERET")   // BC ICMS ST	
   aAdd(_aCampos,"FT_ALIQSOL")   // ALQ ST	
   aAdd(_aCampos,"FT_MARGEM")    // MVA ST	   
   aAdd(_aCampos,"FT_ICMSRET")   // VL ICMS ST	
   aAdd(_aCampos,"FT_BASEDES")   // BASE DIFAL	
   aAdd(_aCampos,"FT_ICMSCOM")   // VL ICMS DIFAL	
   aAdd(_aCampos,"FT_CTIPI")     // CST IPI	
   aAdd(_aCampos,"FT_BASEIPI")   // BC IPI	
   aAdd(_aCampos,"FT_ALIQIPI")   // ALQ IPI	
   aAdd(_aCampos,"FT_VALIPI")    // VL IPI	
   aAdd(_aCampos,"FT_CSTPIS")    // CST PIS	
   aAdd(_aCampos,"FT_BASEPIS")   // BC PIS	
   aAdd(_aCampos,"FT_ALIQPIS")   // ALQ PIS	
   aAdd(_aCampos,"FT_VALPIS")    // VL PIS	
   aAdd(_aCampos,"FT_CSTCOF")    // CST COFINS	
   aAdd(_aCampos,"FT_BASECOF")   // BC COFINS	
   aAdd(_aCampos,"FT_ALIQCOF")   // ALQ COFINS	
   aAdd(_aCampos,"FT_VALCOF")    // VL COFINS	
   aAdd(_aCampos,"FT_VALIRR")    // VL IRRF	
   aAdd(_aCampos,"FT_VALINS")    // VL INSS	
   aAdd(_aCampos,"FT_VRETCSL")   // VL CSSL RET	
   aAdd(_aCampos,"FT_VRETPIS")   // VL PIS RET	
   aAdd(_aCampos,"FT_VRETCOF")   // VL COFINS RET
//--------------------------------------------------------------   
   aAdd(_aCampos,"D1_BASEISS")   // BASE ISS RET
   aAdd(_aCampos,"D1_ALIQISS")   // ALQ ISS RET	
//--------------------------------------------------------------   
   aAdd(_aCampos,"D1_VALISS")    // VL ISS RET	
   aAdd(_aCampos,"FT_VALFUM")    // VL FUNRURAL RET	
   aAdd(_aCampos,"FT_VLSENAR")   // VL SENAR RET	
   aAdd(_aCampos,"FT_VALFUND")   // VL FUNDESA RET	
   aAdd(_aCampos,"F2_I_CTRA")    // COD TRANSPORTADOR	
   aAdd(_aCampos,"F2_I_LTRA")    // LOJA TRANSPORTADOR	
   aAdd(_aCampos,"A2_NOME")      // RAZAO SOCIAL TRANSPORTADOR	
   aAdd(_aCampos,"A2_MUN")       // CIDADE	
   aAdd(_aCampos,"A2_EST")       // UF TRANSP	
   aAdd(_aCampos,"F2_I_PLACA")   // PLACA	 			 	 		 		 	 	 	 	 	 	 	 	 	 	 			 		 	 		  		
   aAdd(_aCampos,"F2_I_FRET")    // VL FRETE	
   aAdd(_aCampos,"F2_TPFRETE")   // TIPO FRETE	
   aAdd(_aCampos,"F4_DUPLIC")    // FINANCEIRO	
   aAdd(_aCampos,"F4_ESTOQUE")   // ESTOQUE
   aAdd(_aCampos,"C7_NUM")       // PEDIDO DE COMPARAS
   aAdd(_aCampos,"C7_OBSMREC")      // OBSERVAÇÃO PEDIDO DE COMPRAS

   _aCabList := {"CODIGO"                        ,;
                 "RAZAO SOCIAL"                  ,;
                 "CNPJ	"                        ,;
                 "IE"                            ,;
                 "IM	"                           ,;
                 "CIDADE	"                     ,;
                 "UF	"                           ,;
                 "DATA EMISSÃO	 "              ,;  
                 "DATA ENT/SAI	"               ,;  
                 "NÚMERO	"                     ,;  
                 "SÉRIE	"                        ,;  
                 "MODELO	"                     ,;  
                 "CHAVE DE ACESSO	"            ,;  
                 "SITUAÇÃO	"                     ,;  
                 "TIPO	"                        ,;  
                 "TIPO	LANC"                    ,;  
                 "COD. TES	"                     ,;  
                 "DESCRIÇÃO TES	"               ,;  
                 "CFOP	"                        ,;  
                 "NATUREZA DE OPERAÇÃO	"         ,; 
                 "DESCRIÇÃO NATUREZA	"         ,; 
                 "NÚMERO NOTA ORIGEM	"         ,;  
                 "SÉRIE NOTA DE ORIGEM	"         ,;
                 "COD. CENTRO DE CUSTO	"         ,;
                 "DESCRIÇÃO DO CENTRO DE CUSTO"  ,;
                 "COD. CLIENTE/FORN	"            ,;
                 "LOJA CLIENTE/FORN	"            ,;
                 "RAZAO SOCIAL CLIENTE/FORN	"   ,;
                 "CNPJ OU CPF CLIENTE/FORN	"   ,;
                 "IE CLIENTE/FORN	"            ,;
                 "CIDADE 	"                     ,;
                 "UF	"                           ,;
                 "CÁLCULO IRRF"                  ,; 
                 "OPT.SIMPLES NACIONAL"          ,; 
                 "ARMAZÉM/DEPÓSITO	"            ,;
                 "COD GRUPO DE PRODUTO	"         ,;
                 "DESCRICAO GRUPO PRODUTO	"      ,;
                 "COD. PRODUTO	"               ,;
                 "DESCRICAO PRODUTO	"            ,;
                 "NCM	"                        ,;
                 "UNIDADE DE MEDIDA	"            ,;
                 "QUANTIDADE	"                  ,;
                 "VL UNITARIO	"                  ,;
                 "VL DESCONTO	"                  ,;
                 "DESPESAS	"                     ,;
                 "FRETE	"                        ,;
                 "SEGURO	"                     ,;
                 "VL TOTAL ITEM	"               ,;
                 "VL TOTAL NF	"                  ,;
                 "CST ICMS	"                     ,;
                 "BC ICMS	"                     ,;
                 "ALQ ICMS	"                     ,;
                 "VL ICMS	"                     ,;
                 "ICMS ANTECIPADO"               ,;     
                 "BC ICMS ST	"                  ,;
                 "ALQ ST	"                     ,;
                 "MVA ST	   "                  ,;
                 "VL ICMS ST	"                  ,;
                 "BASE DIFAL	"                  ,;
                 "VL ICMS DIFAL	"               ,;
                 "CST IPI	"                     ,;
                 "BC IPI	"                     ,;
                 "ALQ IPI	"                     ,;
                 "VL IPI	"                     ,;
                 "CST PIS	"                     ,;
                 "BC PIS	"                     ,;
                 "ALQ PIS	"                     ,;
                 "VL PIS	"                     ,;
                 "CST COFINS	"                  ,;
                 "BC COFINS	"                  ,;
                 "ALQ COFINS	"                  ,;
                 "VL COFINS	"                  ,;
                 "VL IRRF	"                     ,;
                 "VL INSS	"                     ,;
                 "VL CSSL RET	"                  ,;
                 "VL PIS RET	"                  ,;
                 "VL COFINS RET	"               ,;
                 "BASE ISS RET "                 ,;
                 "ALQ ISS RET	"                  ,;
                 "VL ISS RET	"                  ,;
                 "VL FUNRURAL RET	"            ,;
                 "VL SENAR RET	"               ,;
                 "VL FUNDESA RET	"               ,;
                 "COD TRANSPORTADOR	"            ,;
                 "LOJA TRANSPORTADOR	"         ,;
                 "RAZAO SOCIAL TRANSPORTADOR"    ,;
                 "CIDADE	"                     ,;
                 "UF TRANSP	"                  ,;
                 "PLACA"                         ,;
                 "VL FRETE	"                     ,; 
                 "TIPO FRETE	"                  ,;
                 "FINANCEIRO	"                  ,;
                 "ESTOQUE 	 		"               ,;
                 "PEDIDO DE COMPRAS"             ,;
                 "OBSERVAÇÃO PEDIDO DE COMPRAS "  }

aAdd(_aCabExcel,{	"CODIGO"    	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"RAZAO SOCIAL" 	               ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CNPJ "    	                     ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"IE"      	                     ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"IM "      	                     ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CIDADE  "   	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"UF "      	                     ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DATA EMISSÃO  "                 ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DATA ENT/SAI  "                 ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"NÚMERO  "    	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"SÉRIE "     	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"MODELO  "    	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CHAVE DE ACESSO  "              ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"SITUAÇÃO "    	               ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"TIPO "     	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"TIPO LANC"   	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"COD. TES "    	               ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DESCRIÇÃO TES "                 ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CFOP "     	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"NATUREZA DE OPERAÇÃO "          ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DESCRIÇÃO NATUREZA  "           ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"NÚMERO NOTA ORIGEM  "      	   ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"SÉRIE NOTA DE ORIGEM "     	   ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"COD. CENTRO DE CUSTO "     	   ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DESCRIÇÃO DO CENTRO DE CUSTO" 	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"COD. CLIENTE/FORN "      	      ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"LOJA CLIENTE/FORN "      	      ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"RAZAO SOCIAL CLIENTE/FORN "  	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CNPJ OU CPF CLIENTE/FORN  "  	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"IE CLIENTE/FORN  "      	      ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CIDADE  "   	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"UF "                         	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CÁLCULO IRRF"  	               ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"OPT.SIMPLES NACIONAL"      	   ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"ARMAZÉM/DEPÓSITO "      	      ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"COD GRUPO DE PRODUTO "     	   ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DESCRICAO GRUPO PRODUTO "    	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"COD. PRODUTO  "              	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"DESCRICAO PRODUTO "           	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"NCM  "                       	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"UNIDADE DE MEDIDA "            	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"QUANTIDADE " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL UNITARIO " 	               ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL DESCONTO "                	,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"DESPESAS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"FRETE "    	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"SEGURO  "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL TOTAL ITEM "                	,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL TOTAL NF " 	               ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"CST ICMS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"BC ICMS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ALQ ICMS "                   	,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL ICMS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ICMS ANTECIPADO"             	,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"BC ICMS ST " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ALQ ST  "                    	,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"MVA ST   " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL ICMS ST " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"BASE DIFAL " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL ICMS DIFAL"                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"CST IPI "   	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"BC IPI  "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ALQ IPI "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL IPI  "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"CST PIS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"BC PIS  "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ALQ PIS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL PIS  "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"CST COFINS " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"BC COFINS  " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ALQ COFINS " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL COFINS  " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL IRRF "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL INSS "   	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL CSSL RET " 	               ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL PIS RET " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL COFINS RET "        	      ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"BASE ISS RET "         	      ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"ALQ ISS RET " 	               ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL ISS RET " 	                  ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL FUNRURAL RET  "      	      ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL SENAR RET  "        	      ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"VL FUNDESA RET "        	      ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"COD TRANSPORTADOR "      	      ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"LOJA TRANSPORTADOR  "     	   ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"RAZAO SOCIAL TRANSPORTADOR"  	,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"CIDADE  "   	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"UF TRANSP  " 	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"PLACA"     	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"VL FRETE "    	               ,	3	,	2	,	.F.	})
aAdd(_aCabExcel,{	"TIPO FRETE " 	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"FINANCEIRO " 	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"ESTOQUE    "	                  ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"PEDIDO DE COMPRAS"	            ,	1	,	1	,	.F.	})
aAdd(_aCabExcel,{	"OBSERVAÇÃO PEDIDO DE COMPRAS "  ,	1	,	1	,	.F.	})

Return

Static Function TipoLanc(_cTipoLanc)

If _cTipoLanc ="P"
   _cTipoLanc:="P-COMPL.IPI + ICMS"
ElseIf _cTipoLanc ="I"
   _cTipoLanc:="I-COMPL.ICMS"
ElseIf _cTipoLanc ="B"
   _cTipoLanc:="B-BENEFICIAMENTO"
ElseIf _cTipoLanc ="C"
   _cTipoLanc:="C-CTE"
ElseIf _cTipoLanc ="D"
   _cTipoLanc:="D-DEVOLUCAO"
ElseIf _cTipoLanc ="S"
   _cTipoLanc:="S-NF COM ISS"
ElseIf _cTipoLanc ="L"
   _cTipoLanc:="L-NF SEM LOTE"
ElseIf _cTipoLanc =" "
   _cTipoLanc:=" "//NF CANCELADA
EndIf

Return _cTipoLanc
