/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
 
#DEFINE CRLF Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa--------: ROMS071
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/09/2022
Descrição-------: Relatório de Notas Fiscais Canceladas/Exluidas de Pallet Chep. Chamado 40893.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS071()

Local _oReport
Local _cPerg := "ROMS071"

Private _oSection2

Begin Sequence 
   _aItalac_F3 :={}

   _cSelectSA1:="SELECT DISTINCT A1_COD, A1_NOME, A1_LOJA   FROM "+RETSQLNAME("SA1")+" SA1 WHERE A1_MSBLQL <> '1' AND D_E_L_E_T_ = ' ' ORDER BY A1_COD, A1_LOJA " 
   _bCondSA1  := NIL//{|| If(MV_PAR07="2",(A1_MSBLQL = "1"),(A1_MSBLQL <> "1")) }
   //aAdd(_aItalac_F3,{"MV_PAR01","SA1",SA1->(FIELDPOS("A1_COD")),{|| SA1->A1_LOJA+"-"+SA1->A1_NOME } ,_bCondSA1 ,"Clientes",,,} )
   aAdd(_aItalac_F3,{"MV_PAR05",_cSelectSA1,{|Tab| (Tab)->A1_COD + (Tab)->A1_LOJA }, {|Tab| (Tab)->A1_NOME } ,_bCondSA1 ,"Clientes",,,30,.F.        ,       , } )

   Pergunte(_cPerg,.T.,"Tela de Filtro do Relatório NFs Canceladas/Excluidas de Pallet Chep")

   _oReport := Report()
   _oReport:PrintDialog()

End Sequence 

Return 

/*
===============================================================================================================================
Programa--------: Report
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/09/2022
Descrição-------: Função de controle da impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Report()

Local _oReport
Local _oSection1 
Local _cAliasSA1 := "SA1"
Local _cAliasSF2 := "SF2"
Local _cAliasQRY := GetNextAlias()

_oReport := TReport():New("ROMS071","Relatório de NFs Canceladas/Excluidas de Pallet Chep",,{|_oReport| U_ROMS071P(_oReport,_cAliasSA1,_cAliasSF2,_cAliasQRY)},"Relatório de NFs Canceladas/Excluidas de Pallet Chep")

_oSection := TRSection():New(_oReport,"Relatório de NFs Canceladas/Excluidas de Pallet Chep"	,{"SF2","SD2","SA1"},{},.F.,.T.)
_oSection:SetTotalInLine(.F.)
TRCell():New(_oSection,"_Filial"		,/*Tabela*/,"Filial"	,/*Picture*/					,	40					,/*lPixel*/	,{||_Filial	}/*Block*/		 )

_oSection1 := TRSection():New(_oSection,"Nota Fiscais"		,{"SF2","SD2","SA1"})

_oSection1:SetTotalInLine(.F.)

TRCell():New(_oSection1,"NOTA"		,/*Tabela*/,"Nota Fiscal"		,/*Picture*/			,15		,/*lPixel*/	,{||NOTA	}        /*Block*/)
TRCell():New(_oSection1,"SERIE"		,/*Tabela*/,"Serie"				,/*Picture*/			,03		,/*lPixel*/	,{||SERIE	}     /*Block*/)
TRCell():New(_oSection1,"EMISSAO"	,/*Tabela*/,"Emissao"			,/*Picture*/			,15		,/*lPixel*/	,{||SToD(EMISSAO)}/*Block*/)
TRCell():New(_oSection1,"TIPO_NF"	,/*Tabela*/,"Tipo NF"			,/*Picture*/			,15		,/*lPixel*/	,{||TIPO_NF}      /*Block*/)
TRCell():New(_oSection1,"CLIENTE"	,/*Tabela*/,"Cliente"			,/*Picture*/			,06		,/*lPixel*/	,{||CLIENTE}      /*Block*/)
TRCell():New(_oSection1,"LOJA"		,/*Tabela*/,"Loja"	  			,/*Picture*/			,04		,/*lPixel*/	,{||LOJA	}        /*Block*/)
TRCell():New(_oSection1,"NOME"		,/*Tabela*/,"Nome"		    	,/*Picture*/ 			,60		,/*lPixel*/	,                 /*Block*/) // {||NOME	}  
TRCell():New(_oSection1,"CHAVE_NF"	,/*Tabela*/,"Chave NF"			,/*Picture*/			,50		,/*lPixel*/	,{||CHAVE_NF}     /*Block*/)
TRCell():New(_oSection1,"PEDIDO"	   ,/*Tabela*/,"Pedido Vendas"	,/*Picture*/			,14		,/*lPixel*/	,{||PEDIDO}       /*Block*/)
TRCell():New(_oSection1,"QUANT"		,/*Tabela*/,"Qtde"				,"@E 999,999,999.99"	,14		,/*lPixel*/	,{||QUANT	}     /*Block*/)
TRCell():New(_oSection1,"VALOR_NF"	,/*Tabela*/,"Valor NF"	      ,"@E 999,999,999.99"	,14		,/*lPixel*/	,{||VALOR_NF}     /*Block*/)

Return _oReport

/*
===============================================================================================================================
Programa--------: ROMS071P
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/09/2022
Descrição-------: Função que Processa a impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS071P(_oReport,_cAliasSB1,_cAliasSB5,_cAliasQRY)

Local _oSection1 := _oReport:Section(1)
Local _cFiltro   := "%"
Local _cNome := " "

Begin Sequence 
   
   If ! Empty(MV_PAR01) // De Filial  
      _cFiltro +=  " AND D2_FILIAL IN " + FormatIn(MV_PAR01,";")
   EndIf

   If ! Empty(MV_PAR02) // De Emissao  
      _cFiltro += " AND D2_EMISSAO >= '"+DToS(MV_PAR02)+"' "
   EndIf
   
   If ! Empty(MV_PAR03) // Até Emissao 
      _cFiltro += " AND D2_EMISSAO <= '"+DToS(MV_PAR03)+"' "
   EndIf

   If MV_PAR04 == 1
      _cFiltro += " AND F2_CHVNFE <> ' ' AND F2.D_E_L_E_T_ = '*' "
   ElseIf MV_PAR04 == 2
      _cFiltro += " AND F2_CHVNFE = ' '  AND F2.D_E_L_E_T_ = '*' "
   Else 
      _cFiltro += " AND F2.D_E_L_E_T_ = '*' "
   EndIf 

   If !Empty(MV_PAR05)
	  _cFiltro += 	" AND D2.D2_CLIENTE || D2.D2_LOJA IN " + FormatIn(MV_PAR05,";")
   EndIf

   If MV_PAR06 == 1
      _cFiltro += " AND F2_TIPO = 'N' "
   ElseIf MV_PAR06 == 2
      _cFiltro += " AND F2_TIPO <> 'N' "
   EndIf 

   _cFiltro += 	"%"

   _oSection1:BeginQuery()

   BeginSql alias _cAliasQRY

	  SELECT D2.D2_FILIAL FILIAL,
		   D2.D2_DOC NOTA,
	  	   D2.D2_SERIE SERIE,
		   D2.D2_EMISSAO EMISSAO,
		   D2.D2_CLIENTE CLIENTE,
		   D2.D2_LOJA LOJA,
		   D2.D2_PEDIDO PEDIDO,    // A1.A1_NOME NOME,
		   F2.F2_VALBRUT VALOR_NF,
		   F2.F2_CHVNFE CHAVE_NF,
         F2.F2_TIPO TIPO_NF,
    	   SUM(D2.D2_QUANT-D2.D2_QTDEDEV) QUANT

	  FROM %Table:SD2% D2   // LEFT JOIN %Table:SA1% A1 ON (D2.D2_CLIENTE = A1.A1_COD AND D2_LOJA = A1.A1_LOJA AND A1.%notDel% )
	       LEFT JOIN %Table:SF2% F2 ON (F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA)
	  WHERE D2.D2_COD = '08130000002'
           %exp:_cFiltro%
     GROUP BY D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_EMISSAO, D2.D2_CLIENTE, D2.D2_LOJA, D2.D2_PEDIDO, F2.F2_VALBRUT, F2.F2_CHVNFE, F2.F2_TIPO // A1.A1_NOME,
	  ORDER BY D2.D2_FILIAL, D2.D2_DOC, D2.D2_SERIE, D2.D2_CLIENTE, D2.D2_LOJA

   EndSql

   _oSection1:EndQuery()

   _cFilial := (_cAliasQRY)->FILIAL
   _Filial := _cFilial + '-' + FWFilialName(,_cFilial)

   _oReport:Section(1):Init()
   _oReport:Section(1):PrintLine() 
   _oReport:Section(1):Section(1):Init()
   _oReport:Section(1):ShowParamPage()
   _oReport:Section(1):lParamPage := .T.

   While (_cAliasQRY)->(!Eof())
    
	  If _oReport:Cancel()
	     Exit
      EndIf

	  _oReport:IncMeter()

     If (_cAliasQRY)->TIPO_NF == "D" .Or. (_cAliasQRY)->TIPO_NF == "B"
        _cNome := Posicione("SA2",1,xFilial("SA2")+(_cAliasQRY)->CLIENTE+(_cAliasQRY)->LOJA,"A2_NOME")
     Else 
        _cNome := Posicione("SA1",1,xFilial("SA1")+(_cAliasQRY)->CLIENTE+(_cAliasQRY)->LOJA,"A1_NOME")
     EndIf 

     If _cFilial <> (_cAliasQRY)->FILIAL
    	  _oReport:Section(1):Finish()
    	  _oReport:Section(1):Section(1):Finish()
    	  _cFilial := (_cAliasQRY)->FILIAL
		  _Filial := _cFilial + '-' + FWFilialName(,_cFilial)

		  _oReport:Section(1):Init()
		  _oReport:Section(1):PrintLine() 
        _oReport:Section(1):Section(1):Init()
     EndIf
    
      _oReport:Section(1):Section(1):Cell("NOME"):SetValue(_cNome)    

      _oReport:Section(1):Section(1):PrintLine() 
	  
	  (_cAliasQRY)->(DBSkip())
   
   EndDo

   _oReport:Section(1):SetPageBreak(.T.)
   _oReport:Section(1):Finish()
   _oReport:Section(1):Section(1):Finish()

End Sequence 

Return
