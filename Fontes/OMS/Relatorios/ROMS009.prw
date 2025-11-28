/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |14/03/2022| Chamado 28010. Incluida impressão da coluna de formulário proprio (D1_FORMUL).
Julio Paz     |19/08/2024| Chamado 47782. Inclusão de nova coluna para informar o tipo de averbação de carga.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
============================================================================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Bremmer Souza    - Julio Paz         - 11/10/2024 - 21/10/2024 -  48702  - Corrigir o Relatório de Distribuição para Sintetizar Produtos na Opção Sintética do Relatório [OMS]
Jerry Santiago   - Igor Melgaço      - 29/01/2025 - 26/02/2025 -  48994  - Inclusão de novos campos em modo excel.
============================================================================================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "report.ch"
#Include "TOTVS.ch"

#DEFINE ENTER	Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa----------: ROMS009
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Relatorio de devolucao de vendas
Parametros--------: Nenhum 
Retorno-----------: Nenhum 
===============================================================================================================================
*/    
User Function ROMS009() As Logical

Local nOpc       := 0 As Numeric
Local aDesc      := "Confirma impressao?" As Char

Private Exec       := .F. As Logical
Private cIndexName := '' As Char
Private cIndexKey  := '' As Char
Private cPerg      := "ROMS009" As Char
Private cFilter    := '' As Char
Private _cAliasSD1 := GetNextAlias() As Char

If ! Pergunte (cPerg,.T.)
	Return
EndIf

nOpc := Aviso("Impressao de devolução de vendas",aDesc,{"Sim","Nao","Configura"})
If nOpc == 3
	U_ROMS009C()
	nOpc := Aviso("Impressao de devolução de vendas",aDesc,{"Sim","Nao"})
EndIf

If nOpc == 1
   Processa({|lEnd|ROM009R()})
EndIf   

Return   

/*
===============================================================================================================================
Programa----------: ROMS009R
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Alimentacao da query para o relatorio   
Parametros--------: Nenhum

Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROM009R() As Logical

Local oPrint As Object
Private oFont8 As Object
Private oFont8n As Object
Private oFont9 As Object
Private oFont10 As Object
Private oFont12 As Object
Private oFont13 As Object
Private oFont16 As Object
Private oFont20 As Object
Private oFont24 As Object
Private oBrush As Object
Private _nLin As Numeric
Private oFont16n As Object
Private _nPag As Numeric


//Parâmetros de TFont.New()
//1.Nome da Fonte (Windows)
//3.Tamanho em Pixels
//5.Bold (T/F)

oFont8		:= 	TFont():New("Arial",9,6 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont8n		:= 	TFont():New("Arial",9,6 ,.T.,.T.,5,.T.,5,.T.,.F.)
oFont9  	:= 	TFont():New("Arial",9,7 ,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10 	:= 	TFont():New("Arial",9,08,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10n 	:= 	TFont():New("Arial",9,08,.T.,.T.,5,.T.,5,.T.,.F.)
oFont12n 	:= 	TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oFont12  	:= 	TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
oFont14		:= 	TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
oFont14n	:= 	TFont():New("Arial",9,12,.T.,.F.,5,.T.,5,.T.,.F.)
oFont16 	:= 	TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
oFont16n	:= 	TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
oFont20 	:= 	TFont():New("Arial",9,18,.T.,.T.,5,.T.,5,.T.,.F.)
oFont24 	:=	TFont():New("Arial",9,22,.T.,.T.,5,.T.,5,.T.,.F.)

oBrush:=TBrush():New("",4)
_nPag :=1
_nLin :=10


If MV_PAR26 == 2 .And. MV_PAR22 == 1 // Produto/sintetico              

     _cQuery := " SELECT A.D1_FILIAL, A.D1_COD, A.D1_UM, A.D1_SEGUM, SUM(A.D1_QUANT) AS QUANT, SUM(A.D1_QTSEGUM) AS QTSEGUM, SUM(A.D1_TOTAL) AS TOTAL, SUM(A.D1_ICMSRET) AS ICMSRET, SUM(A.D1_DESPESA) AS DESPESA "
     If MV_PAR30 == 2 //Emissão Excel
        _cQuery += ", A.D1_LOCAL ,  F.F2_I_NFSED, A.D1_FORMUL "    
	 EndIf

     _aheader := {"Filial","Produto","Descrição","Unidade","Seg Unid", "Qtde"                ,"Qtde 2a.Unid"               ,"Valor"                  ,"Icms Retido"                ,"Despesa"                    ,"Armazem","SEDEX","Formul"}


ElseIf MV_PAR26 == 3 .And. MV_PAR22 == 1 // Rede/sintetico              

     _cQuery := " SELECT A.D1_FILIAL, B.A1_GRPVEN, A.D1_COD, A.D1_UM, A.D1_SEGUM, SUM(A.D1_QUANT) AS QUANT, SUM(A.D1_QTSEGUM) AS QTSEGUM, SUM(A.D1_TOTAL) AS TOTAL, SUM(A.D1_ICMSRET) AS ICMSRET, SUM(A.D1_DESPESA) AS DESPESA "     
     If MV_PAR30 == 2 //Emissão Excel
        _cQuery += ", A.D1_LOCAL ,  F.F2_I_NFSED, A.D1_FORMUL "    
	 EndIf

     _aheader := {"Filial","Grupo","Nome Grupo","Produto","Descrição","Unidade","Seg Unid", "Qtde"        ,"Qtde 2a.Unid"               ,"Valor"                  ,"Icms Retido"                ,"Despesa"                    ,"Armazem","SEDEX","Formul"}

ElseIf MV_PAR26 == 4 .And. MV_PAR22 == 1 // Cliente/sintetico              

     _cQuery := " SELECT A.D1_FILIAL, B.A1_GRPVEN, A.D1_FORNECE, A.D1_LOJA, A.D1_COD, A.D1_UM, A.D1_SEGUM, SUM(A.D1_QUANT) AS QUANT, SUM(A.D1_QTSEGUM) AS QTSEGUM, SUM(A.D1_TOTAL) AS TOTAL, SUM(A.D1_ICMSRET) AS ICMSRET, SUM(A.D1_DESPESA) AS DESPESA "    
     If MV_PAR30 == 2 //Emissão Excel
        _cQuery += ", A.D1_LOCAL ,  F.F2_I_NFSED, A.D1_FORMUL "    
	 EndIf

     _aheader := {"Filial","Grupo","Nome Grupo","Cliente","Loja","Razão Social", "Produto","Descrição","Unidade","Seg Unid", "Qtde","Qtde 2a.Unid"               ,"Valor"                  ,"Icms Retido"                ,"Despesa"                    ,"Armazem","SEDEX","Formul"}

Else //ANALITICO ******************************************
  
    
      _cQuery := " SELECT D1_FILIAL,"
      _cQuery += "       a.d1_fornece,"
      _cQuery += "       a.d1_loja,"
      _cQuery += "       a.D1_EMISSAO,"
      _cQuery += "       a.D1_DOC,"
      _cQuery += "       a.D1_SERIE,"
      _cQuery += "       a.D1_DATORI,"
      _cQuery += "       a.D1_NFORI,"
      _cQuery += "       a.D1_SERIORI,"
      _cQuery += "       A.D1_COD,"
      _cQuery += "       A.D1_UM,"
      _cQuery += "       A.D1_ITEM,"
      _cQuery += "       A.D1_SEGUM,"
      _cQuery += "       A.D1_QUANT,"
      _cQuery += "       A.D1_QTSEGUM,"
      _cQuery += "       A.D1_TOTAL,"
      _cQuery += "       A.D1_ICMSRET,"
      _cQuery += "       A.D1_DESPESA,"
      _cQuery += "       b.A1_GRPVEN,"
      _cQuery += "       A.D1_DTDIGIT,"
      _cQuery += "       b.A1_NREDUZ,"
      _cQuery += "       b.A1_MUN,"
      _cQuery += "       b.A1_EST,"
      _cQuery += "       C.B1_DESC,"
      _cQuery += "       A.D1_VUNIT,"
	  _cQuery += "       A.D1_LOCAL,"
	  _cQuery += "       F.F2_I_NFSED,
	  _cQuery += "       A.d1_formul,
	  
	  If MV_PAR22 <> 1 // Analitico 
	     _cQuery += "       G.A2_I_TPAVE, " 
		 _cQuery += "       J.A3_COD AS CODVENDEDOR, " 
		 _cQuery += "       J.A3_NOME AS VENDEDOR, " 
		 _cQuery += "       L.A3_COD AS CODCOORDENADOR, "
		 _cQuery += "       L.A3_NOME AS COORDENADOR, "
		 _cQuery += "       M.A3_COD AS CODGERENTE, "  
		 _cQuery += "       M.A3_NOME AS GERENTE, " 
	  EndIf 
      
	  _cQuery += "      (SELECT SUM(SE1.E1_SALDO) FROM " + RETSQLNAME("SE1") + " SE1 WHERE  "
      _cQuery += "                                                               SE1.E1_NUM = A.D1_DOC "
      _cQuery += "                                                               AND SE1.E1_PREFIXO = A.D1_SERIE" 
      _cQuery += "                                                               AND SE1.E1_FILIAL = A.D1_FILIAL" 
      _cQuery += "                                                               AND SE1.E1_CLIENTE = A.D1_FORNECE "
      _cQuery += "                                                               AND SE1.E1_LOJA = A.D1_LOJA AND SE1.D_E_L_E_T_ = ' '  ) SALDO,  "  
      _cQuery += "       (SELECT SUM(SE1.E1_SALDO) FROM " + RETSQLNAME("SE1") + " SE1 WHERE "
      _cQuery += "                                                               SE1.E1_NUM = A.D1_NFORI "
      _cQuery += "                                                               AND SE1.E1_PREFIXO = A.D1_SERIORI" 
      _cQuery += "                                                               AND SE1.E1_FILIAL = A.D1_FILIAL"
      _cQuery += "                                                               AND SE1.E1_CLIENTE = A.D1_FORNECE "
      _cQuery += "                                                               AND SE1.E1_LOJA = A.D1_LOJA AND SE1.D_E_L_E_T_ = ' ' ) SALDOORI  "    

      _aheader := {"Filial"       ,"Emissão NFD" , "Entrada NFD"          ,"Nota Devolução"                       ,"Saldo NFD","DATA NFO"                   ,"Nota Original"                           ,"Saldo NFO"    ,"Grupo"         ,"Nome Grupo"                                                  ,"Cliente"       ,"Loja"        , "Razão Social"                                                           ,"Produto"   ,"Descrição"                                            ,"Unidade"   ,"Seg Unid"   , "Qtde"        ,"Qtde 2a.Unid"  ,"Valor"       ,"Icms Retido"   ,"Despesa","Armazem","SEDEX","Formul"}
     
EndIf

If MV_PAR22 == 1 // Sintetico           
   _cQuery += " FROM "+RetSqlName("SD1")+" A, "+RetSqlName("SF4")+" D ,"+RetSqlName("SA1")+" B, "+RetSqlName("SB1")+" C, "+RetSqlName("SF2")+" F "
Else
   _cQuery += " FROM "+RetSqlName("SD1")+" A, "+RetSqlName("SF4")+" D ,"+RetSqlName("SA1")+" B, "+RetSqlName("SB1")+" C, "+RetSqlName("SF2")+" F, "+RetSqlName("SA2")+" G , "+RetSqlName("SD2")+" H, "+RetSqlName("SC5")+" I , "+RetSqlName("SA3")+" J , "+RetSqlName("SA3")+" L , "+RetSqlName("SA3")+" M "

   aAdd(_aheader,"Tipo Averb.Carga") 
   aAdd(_aheader,"Cod Vendedor") 
   aAdd(_aheader,"Vendedor") 
   aAdd(_aheader,"Cod Coordenador") 
   aAdd(_aheader,"Coordenador") 
   aAdd(_aheader,"Cod Gerente") 
   aAdd(_aheader,"Gerente") 

EndIf 

If MV_PAR21 == 1 // gerou NCC - Gerou Financeiro  

    //NCC com saldo   OU   Totalmente faturada
	If MV_PAR27 == 3 .Or. MV_PAR27 == 2 

		_cQuery += ", " + RetSqlName("SE1")+" E "

	EndIf

EndIf

_cQuery += " WHERE A.D_E_L_E_T_ = ' ' AND D.D_E_L_E_T_ = ' ' AND B.D_E_L_E_T_ = ' ' AND C.D_E_L_E_T_ = ' ' AND F.D_E_L_E_T_ = ' ' AND "

_cQuery += "       A.D1_FORNECE = B.A1_COD AND "
_cQuery += "       A.D1_LOJA = B.A1_LOJA AND "
_cQuery += "       A.D1_COD = C.B1_COD    AND "
_cQuery += "       A.D1_TIPO = 'D' AND "
_cQuery += "       A.D1_FILIAL = D.F4_FILIAL AND "
_cQuery += "       A.D1_TES = D.F4_CODIGO  AND "   
_cQuery += "       F.F2_FILIAL  (+)= A.D1_FILIAL AND "
_cQuery += "       F.F2_DOC     (+)= A.D1_NFORI AND "
_cQuery += "       F.F2_SERIE   (+)= A.D1_SERIORI AND "
_cQuery += "       F.F2_CLIENTE (+)= A.D1_FORNECE AND "
_cQuery += "       F.F2_LOJA    (+)= A.D1_LOJA "

//--------------------------------------------------
If MV_PAR22 <> 1 // Analítico  
   _cQuery += "       AND F.F2_I_CTRA  = G.A2_COD "  
   _cQuery += "       AND F.F2_I_LTRA  = G.A2_LOJA "
   _cQuery += "       AND G.D_E_L_E_T_ = ' ' "

   _cQuery += "       AND A.D1_FILIAL (+)= H.D2_FILIAL  "
   _cQuery += "       AND A.D1_NFORI (+)= H.D2_DOC "
   _cQuery += "       AND H.D_E_L_E_T_ (+)= ' ' "

   _cQuery += "       AND H.D2_FILIAL (+)= I.C5_FILIAL  "
   _cQuery += "       AND H.D2_PEDIDO (+)= I.C5_NUM "
   _cQuery += "       AND I.D_E_L_E_T_ (+)= ' ' "
   
   _cQuery += "       AND I.C5_VEND1 (+)= J.A3_COD "
   _cQuery += "       AND J.D_E_L_E_T_ (+)= ' ' "
   
   _cQuery += "       AND I.C5_VEND2 (+)= L.A3_COD "
   _cQuery += "       AND L.D_E_L_E_T_ (+)= ' ' "

   _cQuery += "       AND I.C5_VEND3 (+)= M.A3_COD "
   _cQuery += "       AND M.D_E_L_E_T_ (+)= ' ' "
   
EndIf 
//--------------------------------------------------

// Filtra SEDEX
If MV_PAR32 == 1
    _cQuery+= " AND F.F2_I_NFSED (+)= 'S' "
ElseIf MV_PAR32 == 2
    _cQuery+= " AND F.F2_I_NFSED (+)= 'N' "
EndIf 

If MV_PAR21 == 1 // gerou NCC - Gerou Financeiro

	 If MV_PAR27 == 3 .Or. MV_PAR27 == 2 
		_cQuery += "       AND A.D1_DOC = E.E1_NUM AND "               
		_cQuery += "       A.D1_SERIE = E.E1_PREFIXO AND "                
		_cQuery += "       A.D1_FORNECE = E.E1_CLIENTE AND "
		_cQuery += "       A.D1_LOJA = E.E1_LOJA AND "  
		_cQuery += "       A.D1_FILIAL = E.E1_FILIAL AND "    
		_cQuery += "       E.D_E_L_E_T_ = ' ' AND "
			//NCC com Saldo
			If MV_PAR27 == 3  
			   _cQuery += "       E.E1_SALDO > 0 "
			Else//NCC totalmente faturadas
		   	   _cQuery += "       E.E1_SALDO = 0 "	
			EndIf
 	   EndIf
EndIf
 
// filtra filiais
If !Empty(AllTrim(MV_PAR01))	
   _cQuery += " AND A.D1_FILIAL IN " + FormatIn(MV_PAR01,";")
EndIf                
// filtra data de entrada 
If !Empty(MV_PAR02) .And. 	!Empty(MV_PAR03)
   _cQuery += " AND A.D1_EMISSAO BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' "
EndIf                 
// filtra data de digitacao
If !Empty(MV_PAR04) .And. 	!Empty(MV_PAR05)
   _cQuery += " AND A.D1_DTDIGIT BETWEEN '"+DToS(MV_PAR04)+"' AND '"+DToS(MV_PAR05)+"' "
EndIf                 
// filtra produto
If !Empty(AllTrim(MV_PAR06)) .And. 	!Empty(AllTrim(MV_PAR07))
   _cQuery += " AND A.D1_COD BETWEEN '"+MV_PAR06+"' AND '"+MV_PAR07+"'  "
EndIf                           			
// filtra Cliente
If !Empty(AllTrim(MV_PAR08)) .And. 	!Empty(AllTrim(MV_PAR10))
   _cQuery += " AND A.D1_FORNECE BETWEEN '"+MV_PAR08+"' AND '"+MV_PAR10+"' "
EndIf                           			
// filtra loja
If !Empty(AllTrim(MV_PAR09)) .And. 	!Empty(AllTrim(MV_PAR11))
   _cQuery += " AND A.D1_LOJA BETWEEN '"+MV_PAR09+"' AND '"+MV_PAR11+"' "
EndIf                           			
//Filtra Rede Cliente
If !Empty(MV_PAR12)
   _cQuery+= " AND B.A1_GRPVEN IN " + FormatIn(MV_PAR12,";")
EndIf
//Filtra Estado Cliente
If !Empty(MV_PAR13) 
   _cQuery+= " AND B.A1_EST IN " + FormatIn(MV_PAR13,";")
EndIf
//Filtra Cod Municipio Cliente
If !Empty(MV_PAR14) 
   _cQuery+= " AND B.A1_COD_MUN IN " + FormatIn(MV_PAR14,";")
EndIf                        

//Filtra vendedor
If !Empty(MV_PAR15) 
    
   _cQuery+= " AND (A.D1_NFORI <> '.' AND A.D1_NFORI IN (SELECT F2_DOC FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_= ' ' AND A.D1_FILIAL = F2_FILIAL AND A.D1_NFORI = F2_DOC AND A.D1_SERIORI = F2_SERIE AND F2_CLIENTE = A.D1_FORNECE AND F2_LOJA = A.D1_LOJA AND F2_VEND1 = '" + MV_PAR15 + "' ))"
      
EndIf
          
//Supervisor
If !Empty(MV_PAR16) 
   
	_cQuery+= " AND (A.D1_NFORI <> '.' AND A.D1_NFORI IN (SELECT F2_DOC FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_= ' ' AND A.D1_FILIAL = F2_FILIAL AND A.D1_NFORI = F2_DOC AND A.D1_SERIORI = F2_SERIE AND F2_CLIENTE = A.D1_FORNECE AND F2_LOJA = A.D1_LOJA AND F2_VEND2 = '" + MV_PAR16 + "' ))"    
       			    
EndIf

//Filtra Grupo de produtos
If !Empty(MV_PAR17) 
   _cQuery+= " AND C.B1_GRUPO IN " + FormatIn(MV_PAR17,";")
EndIf 

//Filtra produtos
If !Empty(MV_PAR18) 
   _cQuery+= " AND C.B1_I_NIV2 IN " + FormatIn(MV_PAR18,";")
EndIf         

//Filtra Tipos de produtos
If !Empty(MV_PAR19) 
   _cQuery+= " AND C.B1_I_NIV3 IN " + FormatIn(MV_PAR19,";")
EndIf

//Filtra marcas de produtos
If !Empty(MV_PAR20) 
   _cQuery+= " AND C.B1_I_NIV4 IN " + FormatIn(MV_PAR20,";")
EndIf

//Filtra Tipo de devolucao     
If MV_PAR21 == 1 // gerou NCC
   _cQuery+= " AND D.F4_DUPLIC='S' "
ElseIf MV_PAR21 == 2 // nao gerou NCC
   _cQuery+= " AND D.F4_DUPLIC<>'S' "
EndIf                                   

// filtra data de faturamento
If !Empty(MV_PAR23) .And. 	!Empty(MV_PAR24)
   
   _cQuery+= " AND (A.D1_NFORI='.' OR (A.D1_NFORI<>'.' AND A.D1_NFORI IN (SELECT F2_DOC FROM " + RetSqlName("SF2") + " WHERE D_E_L_E_T_= ' ' AND A.D1_FILIAL = F2_FILIAL AND A.D1_NFORI = F2_DOC AND A.D1_SERIORI = F2_SERIE AND F2_CLIENTE = A.D1_FORNECE AND F2_LOJA = A.D1_LOJA AND F2_EMISSAO BETWEEN '"+DToS(MV_PAR23)+"' AND '"+DToS(MV_PAR24)+"')))"
   
EndIf

//Filtra Tipo de formulario
If MV_PAR25 == 1 // formulario proprio
   _cQuery+= " AND A.D1_FORMUL='S' "
ElseIf MV_PAR25 == 2 // formulario do cliente
   _cQuery+= " AND A.D1_FORMUL<>'S' "
EndIf         
//Filtra Sub Grupo de produtos
If !Empty(MV_PAR28) 
   _cQuery+= " AND C.B1_I_SUBGR IN " + FormatIn(MV_PAR28,";")
EndIf 

//Filtro para desconsiderar o tes
If !Empty(MV_PAR29) 
   _cQuery+= " AND A.D1_TES NOT IN " + FormatIn(MV_PAR29,";")
EndIf

// Filtra armazém
If !Empty(MV_PAR31) 
   _cQuery+= " AND A.D1_LOCAL IN " + FormatIn(MV_PAR31,";")
EndIf

// Ordem
If MV_PAR26 == 1 // emissao
   _cQuery+= " ORDER BY A.D1_FILIAL, A.D1_DTDIGIT, A.D1_DOC, A.D1_SERIE, A.D1_FORNECE, A.D1_LOJA, A.D1_ITEM"
ElseIf MV_PAR26 == 2 // Produto              
    If MV_PAR22 == 1 // sintetico
       _cQuery+= " GROUP BY A.D1_FILIAL, A.D1_COD, A.D1_UM, A.D1_SEGUM "
       If MV_PAR30 == 2 //Emissão Excel
          _cQuery += ", A.D1_LOCAL ,  F.F2_I_NFSED, A.D1_FORMUL "    
	   EndIf

       _cQuery+= " ORDER BY A.D1_FILIAL, A.D1_COD, A.D1_UM, A.D1_SEGUM " 
    Else // analitico
       _cQuery+= " ORDER BY A.D1_FILIAL, A.D1_COD, A.D1_DTDIGIT, A.D1_DOC, A.D1_SERIE, A.D1_FORNECE, A.D1_LOJA "    
    EndIf       
ElseIf MV_PAR26 == 3 // Rede
    If MV_PAR22 == 1 // sintetico
       _cQuery+= " GROUP BY A.D1_FILIAL, B.A1_GRPVEN, A.D1_COD, A.D1_UM, A.D1_SEGUM "
       If MV_PAR30 == 2 //Emissão Excel
          _cQuery += ", A.D1_LOCAL ,  F.F2_I_NFSED, A.D1_FORMUL "    
	   EndIf

       _cQuery+= " ORDER BY A.D1_FILIAL, B.A1_GRPVEN, A.D1_COD, A.D1_UM, A.D1_SEGUM "
    Else // analitico
       _cQuery+= " ORDER BY A.D1_FILIAL, B.A1_GRPVEN, A.D1_DTDIGIT, A.D1_DOC, A.D1_SERIE "   
    EndIf       
ElseIf MV_PAR26 == 4 // Cliente
    If MV_PAR22 == 1 // sintetico
       _cQuery+= " GROUP BY A.D1_FILIAL, B.A1_GRPVEN, A.D1_FORNECE, A.D1_LOJA, A.D1_COD, A.D1_UM, A.D1_SEGUM "
       If MV_PAR30 == 2 //Emissão Excel
          _cQuery += ", A.D1_LOCAL ,  F.F2_I_NFSED, A.D1_FORMUL "    
	   EndIf

       _cQuery+= " ORDER BY A.D1_FILIAL, B.A1_GRPVEN, A.D1_FORNECE, A.D1_LOJA, A.D1_COD, A.D1_UM, A.D1_SEGUM "
    Else// analitico
       _cQuery+= " ORDER BY A.D1_FILIAL, B.A1_GRPVEN, A.D1_FORNECE, A.D1_LOJA, A.D1_DTDIGIT, A.D1_DOC, A.D1_SERIE "   
    EndIf       
EndIf

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery( _cQuery , _cAliasSD1)

DBSelectArea(_cAliasSD1)

If MV_PAR30 == 2 //Emissão Excel

	//Monta Acols
	(_cAliasSD1)->(DBGoTop())
	_acols := {}
	
	While !((_cAliasSD1)->(Eof()))

		If MV_PAR26 == 2 .And. MV_PAR22 == 1 // Produto/sintetico              

			aAdd(_acols, {(_cAliasSD1)->D1_FILIAL,(_cAliasSD1)->D1_COD,Posicione("SB1",1,xFilial("SB1")+(_cAliasSD1)->D1_COD,"B1_DESC"),(_cAliasSD1)->D1_UM,(_cAliasSD1)->D1_SEGUM,(_cAliasSD1)->QUANT,(_cAliasSD1)->QTSEGUM,(_cAliasSD1)->TOTAL,(_cAliasSD1)->ICMSRET,(_cAliasSD1)->DESPESA,(_cAliasSD1)->D1_LOCAL, If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="S","Sim",If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="N","Não","Vazio")),If(AllTrim((_cAliasSD1)->D1_FORMUL)=="S","Sim",If(AllTrim((_cAliasSD1)->D1_FORMUL)==" "," "," ")) }) 

		ElseIf MV_PAR26 == 3 .And. MV_PAR22 == 1 // Rede/sintetico              

     		aAdd(_acols, {(_cAliasSD1)->D1_FILIAL,(_cAliasSD1)->A1_GRPVEN,Posicione("ACY",1,xFilial("ACY")+(_cAliasSD1)->A1_GRPVEN,"ACY_DESCRI"),(_cAliasSD1)->D1_COD,Posicione("SB1",1,xFilial("SB1")+(_cAliasSD1)->D1_COD,"B1_DESC"),(_cAliasSD1)->D1_UM,(_cAliasSD1)->D1_SEGUM,(_cAliasSD1)->QUANT,(_cAliasSD1)->QTSEGUM,(_cAliasSD1)->TOTAL,(_cAliasSD1)->ICMSRET,(_cAliasSD1)->DESPESA,(_cAliasSD1)->D1_LOCAL, If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="S","Sim",If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="N","Não","Vazio")), If(AllTrim((_cAliasSD1)->D1_FORMUL)=="S","Sim",If(AllTrim((_cAliasSD1)->D1_FORMUL)==" "," "," ")) }) 

     	ElseIf MV_PAR26 == 4 .And. MV_PAR22 == 1 // Cliente/sintetico              

			aAdd(_acols, {(_cAliasSD1)->D1_FILIAL,(_cAliasSD1)->A1_GRPVEN,Posicione("ACY",1,xFilial("ACY")+(_cAliasSD1)->A1_GRPVEN,"ACY_DESCRI"),(_cAliasSD1)->D1_FORNECE, (_cAliasSD1)->D1_LOJA,Posicione("SA1",1,xFilial("SA1")+(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA,"A1_NOME"),(_cAliasSD1)->D1_COD,Posicione("SB1",1,xFilial("SB1")+(_cAliasSD1)->D1_COD,"B1_DESC"),(_cAliasSD1)->D1_UM,(_cAliasSD1)->D1_SEGUM,(_cAliasSD1)->QUANT,(_cAliasSD1)->QTSEGUM,(_cAliasSD1)->TOTAL,(_cAliasSD1)->ICMSRET,(_cAliasSD1)->DESPESA,(_cAliasSD1)->D1_LOCAL, If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="S","Sim",If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="N","Não","Vazio")), If(AllTrim((_cAliasSD1)->D1_FORMUL)=="S","Sim",If(AllTrim((_cAliasSD1)->D1_FORMUL)==" "," "," ")) })  
     		
     	Else // Analitico ou Sintético
            If MV_PAR22 == 1 // Sintetico    
			   aAdd(_acols, {(_cAliasSD1)->D1_FILIAL,DToC(SToD((_cAliasSD1)->D1_EMISSAO)), DToC(SToD((_cAliasSD1)->D1_DTDIGIT)) ,(_cAliasSD1)->D1_DOC + " - " + (_cAliasSD1)->D1_SERIE ,(_cAliasSD1)->SALDO, DToC(SToD((_cAliasSD1)->D1_DATORI)) , (_cAliasSD1)->D1_NFORI + " - " + (_cAliasSD1)->D1_SERIORI, (_cAliasSD1)->SALDOORI, (_cAliasSD1)->A1_GRPVEN,Posicione("ACY",1,xFilial("ACY")+(_cAliasSD1)->A1_GRPVEN,"ACY_DESCRI"),(_cAliasSD1)->D1_FORNECE, (_cAliasSD1)->D1_LOJA,Posicione("SA1",1,xFilial("SA1")+(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA,"A1_NOME"),(_cAliasSD1)->D1_COD,Posicione("SB1",1,xFilial("SB1")+(_cAliasSD1)->D1_COD,"B1_DESC"),(_cAliasSD1)->D1_UM,(_cAliasSD1)->D1_SEGUM,(_cAliasSD1)->D1_QUANT,(_cAliasSD1)->D1_QTSEGUM,(_cAliasSD1)->D1_TOTAL,(_cAliasSD1)->D1_ICMSRET,(_cAliasSD1)->D1_DESPESA,(_cAliasSD1)->D1_LOCAL, If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="S","Sim",If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="N","Não","Vazio")), If(AllTrim((_cAliasSD1)->D1_FORMUL)=="S","Sim",If(AllTrim((_cAliasSD1)->D1_FORMUL)=="N"," "," ")) }) 
			Else // Analítico
               aAdd(_acols, {(_cAliasSD1)->D1_FILIAL,DToC(SToD((_cAliasSD1)->D1_EMISSAO)), DToC(SToD((_cAliasSD1)->D1_DTDIGIT)) ,(_cAliasSD1)->D1_DOC + " - " + (_cAliasSD1)->D1_SERIE ,(_cAliasSD1)->SALDO, DToC(SToD((_cAliasSD1)->D1_DATORI)) , (_cAliasSD1)->D1_NFORI + " - " + (_cAliasSD1)->D1_SERIORI, (_cAliasSD1)->SALDOORI, (_cAliasSD1)->A1_GRPVEN,Posicione("ACY",1,xFilial("ACY")+(_cAliasSD1)->A1_GRPVEN,"ACY_DESCRI"),(_cAliasSD1)->D1_FORNECE, (_cAliasSD1)->D1_LOJA,Posicione("SA1",1,xFilial("SA1")+(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA,"A1_NOME"),(_cAliasSD1)->D1_COD,Posicione("SB1",1,xFilial("SB1")+(_cAliasSD1)->D1_COD,"B1_DESC"),(_cAliasSD1)->D1_UM,(_cAliasSD1)->D1_SEGUM,(_cAliasSD1)->D1_QUANT,(_cAliasSD1)->D1_QTSEGUM,(_cAliasSD1)->D1_TOTAL,(_cAliasSD1)->D1_ICMSRET,(_cAliasSD1)->D1_DESPESA,(_cAliasSD1)->D1_LOCAL, If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="S","Sim",If(AllTrim((_cAliasSD1)->F2_I_NFSED)=="N","Não","Vazio")), If(AllTrim((_cAliasSD1)->D1_FORMUL)=="S","Sim",If(AllTrim((_cAliasSD1)->D1_FORMUL)=="N"," "," ")) , If((_cAliasSD1)->A2_I_TPAVE=="E","EMBARCADOR",If((_cAliasSD1)->A2_I_TPAVE=="T","TRANSPORTADOR","")),(_cAliasSD1)->CODVENDEDOR,(_cAliasSD1)->VENDEDOR,(_cAliasSD1)->CODCOORDENADOR,(_cAliasSD1)->COORDENADOR,(_cAliasSD1)->CODGERENTE,(_cAliasSD1)->GERENTE }) 
			EndIf 
     
     	EndIf
     	
     	(_cAliasSD1)->(DBSkip())
     	
     EndDo


     /*
     Parametros------: _cTitAux	- Título da Janela
     ----------------: _aHeader	- Cabeçalho do conteúdo
     ----------------: _aCols    - Itens do conteúdo
     ----------------: _lMaxSiz  - Define se utiliza o Listbox em tela cheia
     ----------------: _nTipo	- Define se o ListBox é de exibição ou de seleção
     ----------------: _cMsgTop	- Mensagem auxiliar na parte superior do Listbox
     ----------------: _aSizes	- Tamanho das colunas do Listbox
	----------------: _nCampo	- Posição do Array que deve ser retornada em caso de Tela de Seleção Simples
	*/
    If Empty(_aCols)
	   U_ITMsg("Não foram encontrados dados para emissão do relatório, com base nos filtros informados.","Atenção",,1)
	Else 
	   U_ITListBox("Relatório de Devoluções" , _aHeader , _aCols , .T. , 1 , "Exportação excel/arquivo")
    EndIf 
Else

	// Inicializacao da impressao
	oPrint:= TMSPrinter():New( "Relatório de devolução de vendas" )
	oPrint:SetPortrait() // ou SetLandscape()
	oPrint:StartPage()   // Inicia uma nova página
	
	If MV_PAR26==1 // emissao 
		// O parametro .F. eh para nao imprimir o numero da pagina quando For montar a tela de parametros	  
		ROMS009M(oPrint,1,.F.)
		ROMS009P(oPrint)	
		ROMS009I(oPrint)   
	ElseIf MV_PAR26 == 2 .And. MV_PAR22 == 1 // Produto/sintetico 
		ROMS009M(oPrint,2,.F.)
		ROMS009P(oPrint)
		ROMS009I2(oPrint)   
	ElseIf MV_PAR26 == 3 .And. MV_PAR22 == 1 // Rede/sintetico
		ROMS009M(oPrint,3,.F.)
		ROMS009P(oPrint)
		ROMS009I3(oPrint)   
	ElseIf MV_PAR26 == 4 .And. MV_PAR22 == 1  // Cliente/sintetico
		ROMS009M(oPrint,4,.F.)
		ROMS009P(oPrint)
		ROMS009I4(oPrint)  
	ElseIf MV_PAR26 == 2 .And. MV_PAR22 == 2 // Produto/analitico
		ROMS009M(oPrint,5,.F.)
		ROMS009P(oPrint)	
		ROMS009I5(oPrint)   
	ElseIf MV_PAR26 == 3 .And. MV_PAR22 == 2 // Rede/analitico
		ROMS009M(oPrint,6,.F.)
		ROMS009P(oPrint)
		ROMS009I6(oPrint)   
	ElseIf MV_PAR26 == 4 .And. MV_PAR22 == 2  // Cliente/analitico
		ROMS009M(oPrint,7,.F.)
		ROMS009P(oPrint)
		ROMS009I7(oPrint)  
	EndIf

	oPrint:EndPage()     // Finaliza a página
	oPrint:Preview()     // Visualiza antes de imprimir

EndIf

(_cAliasSD1)->(DBCloseArea())
DBSelectArea("SD1")

Return  

/*
===============================================================================================================================
Programa----------: ROMS009I
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel pela impressao dos dados no relatorio     
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009I(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cNomFil := " " As Char
Local _cDoc    := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTDQtd1 := 0 As Numeric
Local _nTDQtd2 := 0 As Numeric
Local _nTDVlr  := 0 As Numeric
Local _nTDBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric

oPrint:StartPage()   // Inicia uma nova página     
ROMS009M(oPrint,1,.T.)
	
DBSelectArea(_cAliasSD1)
While ! Eof()	
	                    
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
	    _nPag++
		oPrint:StartPage()   // Inicia uma nova página
	    ROMS009M(oPrint,1,.T.)
	EndIf
	 
	// Quebra por filial
    _cFilial:=(_cAliasSD1)->D1_FILIAL
    _nTFQtd1:=0
    _nTFQtd2:=0
    _nTFVlr :=0	    	               
    _nTFBrt :=0	    	               
    
    DBSelectArea("SM0")
    _nRecno:=Recno()
    LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
    _cNomFil:=SM0->M0_FILIAL   
    oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFont10n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFont10 )
	oPrint:Say  (_nLin    ,0320,"Filial"       ,oFont10n )
	oPrint:Say  (_nLin+050,0320,_cNomFil,oFont10 )
	_nLin+=135
	DBGoTo(_nRecno)    
	DBSelectArea(_cAliasSD1)

    While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
	    
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página     
		    _nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,1,.T.)		
		EndIf

		// Quebra por nota fiscal de devolucao
	    _cDoc   :=(_cAliasSD1)->D1_DOC+(_cAliasSD1)->D1_SERIE+(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA
	    _nTDQtd1:=0
	    _nTDQtd2:=0
	    _nTDVlr :=0	    	    
        _nTDBrt :=0	    	               

		oPrint:Say  (_nLin    ,0120,"Dt.Entrada" ,oFont10n )
		oPrint:Say  (_nLin+050,0120,DToC(SToD((_cAliasSD1)->D1_DTDIGIT)),oFont10 )
		oPrint:Say  (_nLin    ,0320,"NFD - Serie"  ,oFont10n )
		oPrint:Say  (_nLin+050,0320,(_cAliasSD1)->D1_DOC+"-"+(_cAliasSD1)->D1_SERIE,oFont10 )
		oPrint:Say  (_nLin    ,0590,"NF Ref - Serie" ,oFont10n )
		If AllTrim((_cAliasSD1)->D1_NFORI)<>'.'
		   oPrint:Say  (_nLin+050,0590,(_cAliasSD1)->D1_NFORI+"-"+(_cAliasSD1)->D1_SERIORI,oFont10 )
		EndIf
		oPrint:Say  (_nLin    ,0840,"Cliente-Loja"   ,oFont10n )
		oPrint:Say  (_nLin+050,0840,(_cAliasSD1)->D1_FORNECE+"-"+(_cAliasSD1)->D1_LOJA,oFont10 )
		oPrint:Say  (_nLin    ,1100,"Nome"          ,oFont10n )
		oPrint:Say  (_nLin+050,1100,SubStr((_cAliasSD1)->A1_NREDUZ,1,30) ,oFont10 )
		oPrint:Say  (_nLin    ,1600,"Municipio"     ,oFont10n )
		oPrint:Say  (_nLin+050,1600,(_cAliasSD1)->A1_MUN   ,oFont10 )
		oPrint:Say  (_nLin    ,2000,"Estado"        ,oFont10n )
		oPrint:Say  (_nLin+050,2000,(_cAliasSD1)->A1_EST    ,oFont10 )
        oPrint:Line(_nLin-50,0100,_nLin+100,0100)
        oPrint:Line(_nLin-50,2300,_nLin+100,2300)
        oPrint:Line (_nLin+100,0100,_nLin+100,2300)
	    _nLin+=140

		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
		    _nPag++
			oPrint:StartPage()   // Inicia uma nova página
		    ROMS009M(oPrint,1,.T.)
		EndIf
          
		oPrint:Say (_nLin,0120,"Item"     ,oFont8n )
		oPrint:Say (_nLin,0220,"Produto"  ,oFont8n )
		oPrint:Say (_nLin,1000,"Qtde"     ,oFont8n )
		oPrint:Say (_nLin,1100,"Un.M"     ,oFont8n )
		oPrint:Say (_nLin,1250,"Qtde 2aUM",oFont8n )
		oPrint:Say (_nLin,1450,"2a.UM"    ,oFont8n )
		oPrint:Say (_nLin,1630,"Vlr Uni." ,oFont8n )
		oPrint:Say (_nLin,1850,"Vlr Total",oFont8n )
		oPrint:Say (_nLin,2100,"Vlr Bruto",oFont8n )
        oPrint:Line(_nLin-40,0200,_nLin+050,0200)
        oPrint:Line(_nLin-40,0880,_nLin+050,0880)
        oPrint:Line(_nLin-40,1080,_nLin+050,1080)
        oPrint:Line(_nLin-40,1230,_nLin+050,1230)
        oPrint:Line(_nLin-40,1430,_nLin+050,1430)
        oPrint:Line(_nLin-40,1580,_nLin+050,1580)
        oPrint:Line(_nLin-40,1780,_nLin+050,1780)
        oPrint:Line(_nLin-40,2030,_nLin+050,2030)
        oPrint:Line(_nLin-40,0100,_nLin+050,0100)
        oPrint:Line(_nLin-40,2300,_nLin+050,2300)
        oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=50
		
	    While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cDoc==(_cAliasSD1)->D1_DOC+(_cAliasSD1)->D1_SERIE+(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA
			//imprime cabecalho
			If _nLin>2940
			    oPrint:EndPage() // Finaliza a página
			    _nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,1,.T.)
			EndIf
			oPrint:Say (_nLin,0120,(_cAliasSD1)->D1_ITEM    ,oFont8 )
			oPrint:Say (_nLin,0220,SubStr((_cAliasSD1)->B1_DESC,1,52)    ,oFont8 ) //GUILHERME 23/11/2012 - LIMITE DE IMPRESSAO DESC PRODUTO
			oPrint:Say (_nLin,0880,transform((_cAliasSD1)->D1_QUANT  ,"@re 999,999,999.99")   ,oFont8 )
			oPrint:Say (_nLin,1100,(_cAliasSD1)->D1_UM      ,oFont8 )
			oPrint:Say (_nLin,1245,transform((_cAliasSD1)->D1_QTSEGUM,"@re 999,999,999.99") ,oFont8 )
			oPrint:Say (_nLin,1450,(_cAliasSD1)->D1_SEGUM   ,oFont8 )
			oPrint:Say (_nLin,1600,transform((_cAliasSD1)->D1_VUNIT ,"@re 999,999,999.99")  ,oFont8 )
			oPrint:Say (_nLin,1800,transform((_cAliasSD1)->D1_TOTAL ,"@re 999,999,999.99")  ,oFont8 )
			oPrint:Say (_nLin,2050,transform((_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA ,"@re 999,999,999.99")  ,oFont8 )
		    _nTFQtd1+=(_cAliasSD1)->D1_QUANT
		    _nTFQtd2+=(_cAliasSD1)->D1_QTSEGUM
		    _nTFVlr +=(_cAliasSD1)->D1_TOTAL	    	          
	        _nTFBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA 
		    _nTDQtd1+=(_cAliasSD1)->D1_QUANT
		    _nTDQtd2+=(_cAliasSD1)->D1_QTSEGUM
	    	_nTDVlr +=(_cAliasSD1)->D1_TOTAL	    	    
	        _nTDBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA 
		    _nTQtd1 +=(_cAliasSD1)->D1_QUANT
		    _nTQtd2 +=(_cAliasSD1)->D1_QTSEGUM
	    	_nTVlr  +=(_cAliasSD1)->D1_TOTAL	    	    
	        _nTBrt  +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA 
	        oPrint:Line(_nLin-30,0200,_nLin+050,0200)
	        oPrint:Line(_nLin-30,0880,_nLin+050,0880)
	        oPrint:Line(_nLin-30,1080,_nLin+050,1080)
	        oPrint:Line(_nLin-30,1230,_nLin+050,1230)
	        oPrint:Line(_nLin-30,1430,_nLin+050,1430)
	        oPrint:Line(_nLin-30,1580,_nLin+050,1580)
	        oPrint:Line(_nLin-30,1780,_nLin+050,1780)
	        oPrint:Line(_nLin-30,2030,_nLin+050,2030)
	        oPrint:Line(_nLin-30,0100,_nLin+050,0100)
	        oPrint:Line(_nLin-30,2300,_nLin+050,2300)
	        oPrint:Line(_nLin+050,0100,_nLin+050,2300)
            oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=050
			(_cAliasSD1)->(DBSkip())
	    End                         
		_nLin+=020
		oPrint:Say (_nLin,0120,"Subtotal NFD "+SubStr(_cDoc,1,9)+"-"+SubStr(_cDoc,10,3)   ,oFont8 )
		oPrint:Say (_nLin,0880,transform(_nTDQtd1  ,"@re 999,999,999.99")  ,oFont8 )
		oPrint:Say (_nLin,1245,transform(_nTDQtd2  ,"@re 999,999,999.99")  ,oFont8 )
		oPrint:Say (_nLin,1800,transform(_nTDVlr   ,"@re 999,999,999.99")  ,oFont8 )
		oPrint:Say (_nLin,2050,transform(_nTDBrt   ,"@re 999,999,999.99")  ,oFont8 )
        oPrint:Line(_nLin-40,0100,_nLin+050,0100)
        oPrint:Line(_nLin-40,2300,_nLin+050,2300)
        oPrint:Line(_nLin+050,0100,_nLin+050,2300)
    	_nLin+=100
		//imprime cabecalho
		If _nLin>2800
			oPrint:EndPage() // Finaliza a página
		    _nPag++
			oPrint:StartPage()   // Inicia uma nova página
		    ROMS009M(oPrint,1,.T.)
		EndIf
	    
	End   
    oPrint:Box  (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFont8 )
	oPrint:Say (_nLin,0880,transform(_nTFQtd1,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1245,transform(_nTFQtd2,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1800,transform(_nTFVlr ,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,2050,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFont8 )
	_nLin+=200      
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
	    _nPag++
		oPrint:StartPage()   // Inicia uma nova página
	    ROMS009M(oPrint,1,.T.)
	EndIf
	
End   
oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFont8 )
oPrint:Say (_nLin,0880,transform(_nTQtd1,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,1245,transform(_nTQtd2,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,1800,transform(_nTVlr ,"@re 999,999,999.99") ,oFont8 )           
oPrint:Say (_nLin,2050,transform(_nTBrt ,"@re 999,999,999.99")  ,oFont8 )

oPrint:EndPage() // Finaliza a página
	
Return       

/*
===============================================================================================================================
Programa----------: ROMS009I2
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel por imprimir por Produto/Sintetico     
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS009I2(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cNomFil := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric

oPrint:StartPage()   // Inicia uma nova página
ROMS009M(oPrint,2,.T.)

DBSelectArea(_cAliasSD1)
While ! Eof()
	
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,2,.T.)
	EndIf
	
	// Quebra por filial
	_cFilial:=(_cAliasSD1)->D1_FILIAL
	_nTFQtd1:=0
	_nTFQtd2:=0
	_nTFVlr :=0
	_nTFBrt :=0
	
	DBSelectArea("SM0")
	_nRecno:=Recno()
	LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
	_cNomFil:=SM0->M0_FILIAL
	oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFONT10n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFONT10 )
	oPrint:Say  (_nLin    ,0320,"Filial"       ,oFONT10n )
	oPrint:Say  (_nLin+050,0320,_cNomFil,oFONT10 )
	_nLin+=135
	DBGoTo(_nRecno)
	DBSelectArea(_cAliasSD1)
	
	oPrint:Say (_nLin,0120,"Produto"  ,oFONT10n )
	oPrint:Say (_nLin,0340,"Descrição",oFONT10n )
	oPrint:Say (_nLin,0920,"Qtde"     ,oFONT10n )
	oPrint:Say (_nLin,1120,"Un.M"     ,oFONT10n )
	oPrint:Say (_nLin,1270,"Qtde 2aUM",oFONT10n )
	oPrint:Say (_nLin,1470,"2a.UM"    ,oFONT10n )
	oPrint:Say (_nLin,1670,"Vlr Uni." ,oFONT10n )
	oPrint:Say (_nLin,1820,"Vlr Total",oFONT10n )
	oPrint:Say (_nLin,2070,"Vlr Bruto",oFONT10n )
	oPrint:Line(_nLin-35,0100,_nLin+050,0100)
	oPrint:Line(_nLin-35,0320,_nLin+050,0320)
	oPrint:Line(_nLin-35,0900,_nLin+050,0900)
	oPrint:Line(_nLin-35,1100,_nLin+050,1100)
	oPrint:Line(_nLin-35,1250,_nLin+050,1250)
	oPrint:Line(_nLin-35,1450,_nLin+050,1450)
	oPrint:Line(_nLin-35,1600,_nLin+050,1600)
	oPrint:Line(_nLin-35,1800,_nLin+050,1800)
	oPrint:Line(_nLin-35,2050,_nLin+050,2050)
	oPrint:Line(_nLin-35,2300,_nLin+050,2300)
	oPrint:Line(_nLin+050,0100,_nLin+050,2300)
	_nLin+=50
	
	While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,2,.T.)
		EndIf
		SB1->(DBSeek(xFilial("SB1")+(_cAliasSD1)->D1_COD))
		oPrint:Say (_nLin,0120,(_cAliasSD1)->D1_COD     ,oFONT10 )
		oPrint:Say (_nLin,0340,SubStr(SB1->B1_DESC,1,35)    ,oFONT10 ) // - LIMITE DE IMPRESSAO DESC PRODUTO
		oPrint:Say (_nLin,0900,transform((_cAliasSD1)->QUANT  ,"@re 999,999,999.99")   ,oFONT10 )
		oPrint:Say (_nLin,1175,(_cAliasSD1)->D1_UM      ,oFONT10 )
		oPrint:Say (_nLin,1260,transform((_cAliasSD1)->QTSEGUM,"@re 999,999,999.99") ,oFONT10 )
		oPrint:Say (_nLin,1475,(_cAliasSD1)->D1_SEGUM   ,oFONT10 )
		oPrint:Say (_nLin,1620,transform((_cAliasSD1)->TOTAL / (_cAliasSD1)->QUANT ,"@re 999,999,999.99")  ,oFONT10 )
		oPrint:Say (_nLin,1820,transform((_cAliasSD1)->TOTAL ,"@re 999,999,999.99")  ,oFONT10 )
		oPrint:Say (_nLin,2070,transform((_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA ,"@re 999,999,999.99")  ,oFONT10 )
		_nTFQtd1+=(_cAliasSD1)->QUANT
		_nTFQtd2+=(_cAliasSD1)->QTSEGUM
		_nTFVlr +=(_cAliasSD1)->TOTAL
		_nTFBrt +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA
		_nTQtd1 +=(_cAliasSD1)->QUANT
		_nTQtd2 +=(_cAliasSD1)->QTSEGUM
		_nTVlr  +=(_cAliasSD1)->TOTAL
		_nTBrt  +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA
		oPrint:Line(_nLin-30,0100,_nLin+050,0100)
		oPrint:Line(_nLin-30,0320,_nLin+050,0320)
		oPrint:Line(_nLin-30,0900,_nLin+050,0900)
		oPrint:Line(_nLin-30,1100,_nLin+050,1100)
		oPrint:Line(_nLin-30,1250,_nLin+050,1250)
		oPrint:Line(_nLin-30,1450,_nLin+050,1450)
		oPrint:Line(_nLin-30,1600,_nLin+050,1600)
		oPrint:Line(_nLin-30,1800,_nLin+050,1800)
		oPrint:Line(_nLin-30,2050,_nLin+050,2050)
		oPrint:Line(_nLin-30,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)

		_nLin+=050
		(_cAliasSD1)->(DBSkip())
	End
	oPrint:Box (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFONT10 )
	oPrint:Say (_nLin,0900,transform(_nTFQtd1,"@re 999,999,999.99") ,oFONT10 )
	oPrint:Say (_nLin,1260,transform(_nTFQtd2,"@re 999,999,999.99") ,oFONT10 )
	oPrint:Say (_nLin,1820,transform(_nTFVlr ,"@re 999,999,999.99") ,oFONT10 )
	oPrint:Say (_nLin,2070,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFONT10 )
	_nLin+=200
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,2,.T.)
	EndIf
	
End
oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFONT10 )
oPrint:Say (_nLin,0900,transform(_nTQtd1,"@re 999,999,999.99") ,oFONT10 )
oPrint:Say (_nLin,1260,transform(_nTQtd2,"@re 999,999,999.99") ,oFONT10 )
oPrint:Say (_nLin,1820,transform(_nTVlr ,"@re 999,999,999.99") ,oFONT10 )           
oPrint:Say (_nLin,2070,transform(_nTBrt ,"@re 999,999,999.99")  ,oFONT10 )

oPrint:EndPage() // Finaliza a página
	
Return    

/*
===============================================================================================================================
Programa----------: ROMS009I3
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------:Funcao renponsavel por imprimir por Rede / Sintetico      
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009I3(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cNomFil := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTGQtd1 := 0 As Numeric
Local _nTGQtd2 := 0 As Numeric
Local _nTGVlr  := 0 As Numeric
Local _nTGBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric
Local _cGrupo  := " " As Char

oPrint:StartPage()   // Inicia uma nova página
ROMS009M(oPrint,3,.T.)

DBSelectArea(_cAliasSD1)
While ! Eof()
	
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,3,.T.)
	EndIf
	
	// Quebra por filial
	_cFilial:=(_cAliasSD1)->D1_FILIAL
	_nTFQtd1:=0
	_nTFQtd2:=0
	_nTFVlr :=0
	_nTFBrt :=0
	
	DBSelectArea("SM0")
	_nRecno:=Recno()
	LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
	_cNomFil:=SM0->M0_FILIAL
	oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFont10n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFont10 )
	oPrint:Say  (_nLin    ,0400,"Filial"       ,oFont10n )
	oPrint:Say  (_nLin+050,0400,_cNomFil,oFont10 )
	_nLin+=135
	DBGoTo(_nRecno)
	DBSelectArea(_cAliasSD1)
	
	While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,3,.T.)
		EndIf
		
		// Quebra por grupo de vendas
		_cGrupo :=(_cAliasSD1)->A1_GRPVEN
		_nTGQtd1:=0
		_nTGQtd2:=0
		_nTGVlr :=0
		_nTGBrt :=0
		
		ACY->(DBSeek(xFilial("ACY")+_cGrupo))
		oPrint:Say  (_nLin    ,0120,"Grupo de vendas" ,oFont10n )
		oPrint:Say  (_nLin+050,0120,_cGrupo			,oFont10 )
		oPrint:Say  (_nLin    ,0400,"Descrição"  ,oFont10n )
		oPrint:Say  (_nLin+050,0400,ACY->ACY_DESCRI,oFont10 )
		oPrint:Line(_nLin-50,0100,_nLin+100,0100)
		oPrint:Line(_nLin-50,2300,_nLin+100,2300)
		oPrint:Line (_nLin+100,0100,_nLin+100,2300)
		_nLin+=140
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,3,.T.)
		EndIf
		oPrint:Say (_nLin,0120,"Produto"  ,oFONT10n )
		oPrint:Say (_nLin,0340,"Descrição",oFONT10n )
		oPrint:Say (_nLin,0920,"Qtde"     ,oFONT10n )
		oPrint:Say (_nLin,1120,"Un.M"     ,oFONT10n )
		oPrint:Say (_nLin,1270,"Qtde 2aUM",oFONT10n )
		oPrint:Say (_nLin,1470,"2a.UM"    ,oFONT10n )
		oPrint:Say (_nLin,1670,"Vlr Uni." ,oFONT10n )
		oPrint:Say (_nLin,1820,"Vlr Total",oFONT10n )
		oPrint:Say (_nLin,2070,"Vlr Bruto",oFONT10n )
		oPrint:Line(_nLin-35,0100,_nLin+050,0100)
		oPrint:Line(_nLin-35,0320,_nLin+050,0320)
		oPrint:Line(_nLin-35,0900,_nLin+050,0900)
		oPrint:Line(_nLin-35,1100,_nLin+050,1100)
		oPrint:Line(_nLin-35,1250,_nLin+050,1250)
		oPrint:Line(_nLin-35,1450,_nLin+050,1450)
		oPrint:Line(_nLin-35,1600,_nLin+050,1600)
		oPrint:Line(_nLin-35,1800,_nLin+050,1800)
		oPrint:Line(_nLin-35,2050,_nLin+050,2050)
		oPrint:Line(_nLin-35,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=50
		
		While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cGrupo==(_cAliasSD1)->A1_GRPVEN
			//imprime cabecalho
			If _nLin>2940
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,3,.T.)
			EndIf
			SB1->(DBSeek(xFilial("SB1")+(_cAliasSD1)->D1_COD))
			oPrint:Say (_nLin,0120,(_cAliasSD1)->D1_COD     ,oFONT10 )
			oPrint:Say (_nLin,0340,SubStr(SB1->B1_DESC,1,35)    ,oFONT10 )//GUILHERME 23/11/2012 - LIMITE DE IMPRESSAO DESC PRODUTO
			oPrint:Say (_nLin,0900,transform((_cAliasSD1)->QUANT  ,"@re 999,999,999.99")   ,oFONT10 )
			oPrint:Say (_nLin,1175,(_cAliasSD1)->D1_UM      ,oFONT10 )
			oPrint:Say (_nLin,1260,transform((_cAliasSD1)->QTSEGUM,"@re 999,999,999.99") ,oFONT10 )
			oPrint:Say (_nLin,1475,(_cAliasSD1)->D1_SEGUM   ,oFONT10 )
			oPrint:Say (_nLin,1620,transform((_cAliasSD1)->TOTAL / (_cAliasSD1)->QUANT ,"@re 999,999,999.99")  ,oFONT10 )
			oPrint:Say (_nLin,1820,transform((_cAliasSD1)->TOTAL ,"@re 999,999,999.99")  ,oFONT10 )
			oPrint:Say (_nLin,2070,transform((_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA ,"@re 999,999,999.99")  ,oFONT10 )
			_nTFQtd1+=(_cAliasSD1)->QUANT
			_nTFQtd2+=(_cAliasSD1)->QTSEGUM
			_nTFVlr +=(_cAliasSD1)->TOTAL
			_nTFBrt +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA
			_nTGQtd1+=(_cAliasSD1)->QUANT
			_nTGQtd2+=(_cAliasSD1)->QTSEGUM
			_nTGVlr +=(_cAliasSD1)->TOTAL
			_nTGBrt +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA
			_nTQtd1 +=(_cAliasSD1)->QUANT
			_nTQtd2 +=(_cAliasSD1)->QTSEGUM
			_nTVlr  +=(_cAliasSD1)->TOTAL
			_nTBrt  +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA
			oPrint:Line(_nLin-30,0100,_nLin+050,0100)
			oPrint:Line(_nLin-30,0320,_nLin+050,0320)
			oPrint:Line(_nLin-30,0900,_nLin+050,0900)
			oPrint:Line(_nLin-30,1100,_nLin+050,1100)
			oPrint:Line(_nLin-30,1250,_nLin+050,1250)
			oPrint:Line(_nLin-30,1450,_nLin+050,1450)
			oPrint:Line(_nLin-30,1600,_nLin+050,1600)
			oPrint:Line(_nLin-30,1800,_nLin+050,1800)
			oPrint:Line(_nLin-30,2050,_nLin+050,2050)
			oPrint:Line(_nLin-30,2300,_nLin+050,2300)
			oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=050
			(_cAliasSD1)->(DBSkip())
		End
		
		
		_nLin+=020
		oPrint:Say (_nLin,0120,"Subtotal rede "+_cGrupo+" - "+ACY->ACY_DESCRI   ,oFont10 )
		oPrint:Say (_nLin,0900,transform(_nTGQtd1  ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Say (_nLin,1260,transform(_nTGQtd2  ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Say (_nLin,1820,transform(_nTGVlr   ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Say (_nLin,2070,transform(_nTGBrt   ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Line(_nLin-40,0100,_nLin+050,0100)
		oPrint:Line(_nLin-40,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=100
		//imprime cabecalho
		If _nLin>2800
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,3,.T.)
		EndIf
		
	End
	oPrint:Box  (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFont10 )
	oPrint:Say (_nLin,0900,transform(_nTFQtd1,"@re 999,999,999.99") ,oFont10 )
	oPrint:Say (_nLin,1260,transform(_nTFQtd2,"@re 999,999,999.99") ,oFont10 )
	oPrint:Say (_nLin,1820,transform(_nTFVlr ,"@re 999,999,999.99") ,oFont10 )
	oPrint:Say (_nLin,2070,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFont10 )
	_nLin+=200
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,3,.T.)
	EndIf
	
End
oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFont10 )
oPrint:Say (_nLin,0900,transform(_nTQtd1,"@re 999,999,999.99") ,oFont10 )
oPrint:Say (_nLin,1260,transform(_nTQtd2,"@re 999,999,999.99") ,oFont10 )
oPrint:Say (_nLin,1820,transform(_nTVlr ,"@re 999,999,999.99") ,oFont10 )
oPrint:Say (_nLin,2070,transform(_nTBrt ,"@re 999,999,999.99")  ,oFont10 )

oPrint:EndPage() // Finaliza a página

Return    

/*
===============================================================================================================================
Programa----------: ROMS009I4
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel por imprimir por Cliente / Sintetico           
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009I4(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cNomFil := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTGQtd1 := 0 As Numeric
Local _nTGQtd2 := 0 As Numeric
Local _nTGVlr  := 0 As Numeric
Local _nTGBrt  := 0 As Numeric
Local _nTCQtd1 := 0 As Numeric
Local _nTCQtd2 := 0 As Numeric
Local _nTCVlr  := 0 As Numeric
Local _nTCBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric
Local _cGrupo  := " " As Char
Local _cCliente := " " As Char

oPrint:StartPage()   // Inicia uma nova página
ROMS009M(oPrint,4,.T.)

DBSelectArea(_cAliasSD1)
While ! Eof()
	
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,4,.T.)
	EndIf
	
	// Quebra por filial
	_cFilial:=(_cAliasSD1)->D1_FILIAL
	_nTFQtd1:=0
	_nTFQtd2:=0
	_nTFVlr :=0
	_nTFBrt :=0
	
	DBSelectArea("SM0")
	_nRecno:=Recno()
	LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
	_cNomFil:=SM0->M0_FILIAL
	oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFont10n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFont10 )
	oPrint:Say  (_nLin    ,0400,"Filial"       ,oFont10n )
	oPrint:Say  (_nLin+050,0400,_cNomFil,oFont10 )
	_nLin+=135
	DBGoTo(_nRecno)
	DBSelectArea(_cAliasSD1)
	
	While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,4,.T.)
		EndIf
		
		// Quebra por grupo de vendas
		_cGrupo :=(_cAliasSD1)->A1_GRPVEN
		_nTGQtd1:=0
		_nTGQtd2:=0
		_nTGVlr :=0
		_nTGBrt :=0
		
		ACY->(DBSeek(xFilial("ACY")+_cGrupo))
		oPrint:Say  (_nLin    ,0120,"Grupo de vendas" ,oFont10n )
		oPrint:Say  (_nLin+050,0120,_cGrupo			,oFont10 )
		oPrint:Say  (_nLin    ,0400,"Descrição"  ,oFont10n )
		oPrint:Say  (_nLin+050,0400,ACY->ACY_DESCRI,oFont10 )
		oPrint:Line(_nLin-50,0100,_nLin+100,0100)
		oPrint:Line(_nLin-50,2300,_nLin+100,2300)
		oPrint:Line (_nLin+100,0100,_nLin+100,2300)
		_nLin+=140
		
		While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cGrupo ==(_cAliasSD1)->A1_GRPVEN
			
			//imprime cabecalho
			If _nLin>2940
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,4,.T.)
			EndIf
			
			// Quebra por cliente
			_cCliente:=(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA
			_nTCQtd1:=0
			_nTCQtd2:=0
			_nTCVlr :=0
			_nTCBrt :=0
			SA1->(DBSeek(xFilial("SA1")+(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA))
			oPrint:Say  (_nLin    ,0120,"Código" ,oFont10n )
			oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FORNECE ,oFont10 )
			oPrint:Say  (_nLin    ,0320,"Loja" ,oFont10n )
			oPrint:Say  (_nLin+050,0320,(_cAliasSD1)->D1_LOJA,oFont10 )
			oPrint:Say  (_nLin    ,0520,"Nome Fantasia"  ,oFont10n )
			oPrint:Say  (_nLin+050,0520,SA1->A1_NREDUZ,oFont10 )
			oPrint:Say  (_nLin    ,0920,"Razão Social"  ,oFont10n )
			oPrint:Say  (_nLin+050,0920,SA1->A1_NOME,oFont10 )
			oPrint:Say  (_nLin    ,1620,"Município"  ,oFont10n )
			oPrint:Say  (_nLin+050,1620,SA1->A1_MUN,oFont10 )
			oPrint:Say  (_nLin    ,2120,"Estado"  ,oFont10n )
			oPrint:Say  (_nLin+050,2120,SA1->A1_EST,oFont10 )
			oPrint:Line(_nLin-50,0100,_nLin+100,0100)
			oPrint:Line(_nLin-50,2300,_nLin+100,2300)
			oPrint:Line (_nLin+100,0100,_nLin+100,2300)
			_nLin+=140
			
			
			//imprime cabecalho
			If _nLin>2940
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,4,.T.)
			EndIf
			
			oPrint:Say (_nLin,0120,"Produto"  ,oFONT10n )
			oPrint:Say (_nLin,0340,"Descrição",oFONT10n )
			oPrint:Say (_nLin,0920,"Qtde"     ,oFONT10n )
			oPrint:Say (_nLin,1120,"Un.M"     ,oFONT10n )
			oPrint:Say (_nLin,1270,"Qtde 2aUM",oFONT10n )
			oPrint:Say (_nLin,1470,"2a.UM"    ,oFONT10n )
			oPrint:Say (_nLin,1670,"Vlr Uni." ,oFONT10n )
			oPrint:Say (_nLin,1820,"Vlr Total",oFONT10n )
			oPrint:Say (_nLin,2070,"Vlr Bruto",oFONT10n )
			oPrint:Line(_nLin-35,0100,_nLin+050,0100)
			oPrint:Line(_nLin-35,0320,_nLin+050,0320)
			oPrint:Line(_nLin-35,0900,_nLin+050,0900)
			oPrint:Line(_nLin-35,1100,_nLin+050,1100)
			oPrint:Line(_nLin-35,1250,_nLin+050,1250)
			oPrint:Line(_nLin-35,1450,_nLin+050,1450)
			oPrint:Line(_nLin-35,1600,_nLin+050,1600)
			oPrint:Line(_nLin-35,1800,_nLin+050,1800)
			oPrint:Line(_nLin-35,2050,_nLin+050,2050)
			oPrint:Line(_nLin-35,2300,_nLin+050,2300)
			oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=50
			
			While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cCliente==(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA
				//imprime cabecalho
				If _nLin>2940
					oPrint:EndPage() // Finaliza a página
					_nPag++
					oPrint:StartPage()   // Inicia uma nova página
					ROMS009M(oPrint,4,.T.)
				EndIf
				SB1->(DBSeek(xFilial("SB1")+(_cAliasSD1)->D1_COD))
				oPrint:Say (_nLin,0120,(_cAliasSD1)->D1_COD     ,oFONT10 )
				//oPrint:Say (_nLin,0340,SB1->B1_DESC    ,oFONT10 )
				oPrint:Say (_nLin,0340,SubStr(SB1->B1_DESC,1,35)    ,oFONT10 )//GUILHERME 23/11/2012 - LIMITE DE IMPRESSAO DESC PRODUTO
				oPrint:Say (_nLin,0900,transform((_cAliasSD1)->QUANT  ,"@re 999,999,999.99")   ,oFONT10 )
				oPrint:Say (_nLin,1175,(_cAliasSD1)->D1_UM      ,oFONT10 )
				oPrint:Say (_nLin,1260,transform((_cAliasSD1)->QTSEGUM,"@re 999,999,999.99") ,oFONT10 )
				oPrint:Say (_nLin,1475,(_cAliasSD1)->D1_SEGUM   ,oFONT10 )
				oPrint:Say (_nLin,1620,transform((_cAliasSD1)->TOTAL / (_cAliasSD1)->QUANT ,"@re 999,999,999.99")  ,oFONT10 )
				oPrint:Say (_nLin,1820,transform((_cAliasSD1)->TOTAL ,"@re 999,999,999.99")  ,oFONT10 )
				oPrint:Say (_nLin,2070,transform((_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA ,"@re 999,999,999.99")  ,oFONT10 )//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
				_nTFQtd1+=(_cAliasSD1)->QUANT
				_nTFQtd2+=(_cAliasSD1)->QTSEGUM
				_nTFVlr +=(_cAliasSD1)->TOTAL
				_nTFBrt +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
				_nTGQtd1+=(_cAliasSD1)->QUANT
				_nTGQtd2+=(_cAliasSD1)->QTSEGUM
				_nTGVlr +=(_cAliasSD1)->TOTAL
				_nTGBrt +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
				_nTCQtd1+=(_cAliasSD1)->QUANT
				_nTCQtd2+=(_cAliasSD1)->QTSEGUM
				_nTCVlr +=(_cAliasSD1)->TOTAL
				_nTCBrt +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
				_nTQtd1 +=(_cAliasSD1)->QUANT
				_nTQtd2 +=(_cAliasSD1)->QTSEGUM
				_nTVlr  +=(_cAliasSD1)->TOTAL
				_nTBrt  +=(_cAliasSD1)->TOTAL+(_cAliasSD1)->ICMSRET+(_cAliasSD1)->DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
				oPrint:Line(_nLin-30,0100,_nLin+050,0100)
				oPrint:Line(_nLin-30,0320,_nLin+050,0320)
				oPrint:Line(_nLin-30,0900,_nLin+050,0900)
				oPrint:Line(_nLin-30,1100,_nLin+050,1100)
				oPrint:Line(_nLin-30,1250,_nLin+050,1250)
				oPrint:Line(_nLin-30,1450,_nLin+050,1450)
				oPrint:Line(_nLin-30,1600,_nLin+050,1600)
				oPrint:Line(_nLin-30,1800,_nLin+050,1800)
				oPrint:Line(_nLin-30,2050,_nLin+050,2050)
				oPrint:Line(_nLin-30,2300,_nLin+050,2300)
				oPrint:Line(_nLin+050,0100,_nLin+050,2300)
				_nLin+=050
				(_cAliasSD1)->(DBSkip())
			End
			
			_nLin+=020
			oPrint:Say (_nLin,0120,"Subtotal cliente"+SubStr(_cCliente,1,6)+" - "+SubStr(_cCliente,7,2)+" "+SubStr(SA1->A1_NREDUZ,1,20),oFont10 )
			oPrint:Say (_nLin,0900,transform(_nTCQtd1  ,"@re 999,999,999.99")  ,oFont10 )
			oPrint:Say (_nLin,1260,transform(_nTCQtd2  ,"@re 999,999,999.99")  ,oFont10 )
			oPrint:Say (_nLin,1820,transform(_nTCVlr   ,"@re 999,999,999.99")  ,oFont10 )
			oPrint:Say (_nLin,2070,transform(_nTCBrt   ,"@re 999,999,999.99")  ,oFont10 )
			oPrint:Line(_nLin-40,0100,_nLin+050,0100)
			oPrint:Line(_nLin-40,2300,_nLin+050,2300)
			oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=100
			//imprime cabecalho
			If _nLin>2800
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,4,.T.)
			EndIf
			
		End
		
		
		_nLin+=020
		oPrint:Say (_nLin,0120,"Subtotal rede "+_cGrupo+" - "+ACY->ACY_DESCRI   ,oFont10 )
		oPrint:Say (_nLin,0900,transform(_nTGQtd1  ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Say (_nLin,1260,transform(_nTGQtd2  ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Say (_nLin,1820,transform(_nTGVlr   ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Say (_nLin,2070,transform(_nTGBrt   ,"@re 999,999,999.99")  ,oFont10 )
		oPrint:Line(_nLin-100,0100,_nLin+050,0100)
		oPrint:Line(_nLin-100,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=100
		//imprime cabecalho
		If _nLin>2800
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,4,.T.)
		EndIf
		
	End
	oPrint:Box  (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFont10 )
	oPrint:Say (_nLin,0900,transform(_nTFQtd1,"@re 999,999,999.99") ,oFont10 )
	oPrint:Say (_nLin,1260,transform(_nTFQtd2,"@re 999,999,999.99") ,oFont10 )
	oPrint:Say (_nLin,1820,transform(_nTFVlr ,"@re 999,999,999.99") ,oFont10 )
	oPrint:Say (_nLin,2070,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFont10 )
	_nLin+=200
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,4,.T.)
	EndIf
	
End

oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFont10 )
oPrint:Say (_nLin,0900,transform(_nTQtd1,"@re 999,999,999.99") ,oFont10 )
oPrint:Say (_nLin,1260,transform(_nTQtd2,"@re 999,999,999.99") ,oFont10 )
oPrint:Say (_nLin,1820,transform(_nTVlr ,"@re 999,999,999.99") ,oFont10 )
oPrint:Say (_nLin,2070,transform(_nTBrt ,"@re 999,999,999.99")  ,oFont10 )

oPrint:EndPage() // Finaliza a página

Return      

/*
===============================================================================================================================
Programa----------: ROMS009I5
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel por imprimir por Produto/Analitico         
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009I5(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cProd   := " " As Char
Local _cNomFil := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTPQtd1 := 0 As Numeric
Local _nTPQtd2 := 0 As Numeric
Local _nTPVlr  := 0 As Numeric
Local _nTPBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric

oPrint:StartPage()   // Inicia uma nova página
ROMS009M(oPrint,5,.T.)

DBSelectArea(_cAliasSD1)
While ! Eof()
	
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,5,.T.)
	EndIf
	
	// Quebra por filial
	_cFilial:=(_cAliasSD1)->D1_FILIAL
	_nTFQtd1:=0
	_nTFQtd2:=0
	_nTFVlr :=0
	_nTFBrt :=0
	
	DBSelectArea("SM0")
	_nRecno:=Recno()
	LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
	_cNomFil:=SM0->M0_FILIAL
	oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFont10n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFont10 )
	oPrint:Say  (_nLin    ,0370,"Filial"       ,oFont10n )
	oPrint:Say  (_nLin+050,0370,_cNomFil,oFont10 )
	_nLin+=150
	DBGoTo(_nRecno)
	DBSelectArea(_cAliasSD1)
	
	While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,5,.T.)
		EndIf
		
		// Quebra por produto
		oPrint:Say (_nLin,0120,"Produto"  ,oFont10n )
		oPrint:Say (_nLin,0370,"Descrição",oFont10n )
		oPrint:Line(_nLin-50,0100,_nLin+050,0100)
		oPrint:Line(_nLin-50,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=75
		
		
		SB1->(DBSeek(xFilial("SB1")+(_cAliasSD1)->D1_COD))
		oPrint:Say (_nLin,0120,(_cAliasSD1)->D1_COD     ,oFont10 )
		oPrint:Say (_nLin,0370,SB1->B1_I_DESCD  ,oFont10 )
		oPrint:Line(_nLin-35,0100,_nLin+050,0100)
		oPrint:Line(_nLin-35,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=75
		
		_cProd  :=(_cAliasSD1)->D1_COD
		_nTPQtd1:=0
		_nTPQtd2:=0
		_nTPVlr :=0
		_nTPBrt :=0
		
		oPrint:Say (_nLin,0120,"Dt.Entr." ,oFont8n )
		oPrint:Say (_nLin,0270,"NFD-Serie"  ,oFont8n )
		oPrint:Say (_nLin,0470,"NF Ref-Serie" ,oFont8n )
		oPrint:Say (_nLin,0670,"Cliente-Loja"   ,oFont8n )
		oPrint:Say (_nLin,0870,"Nome"          ,oFont8n )
		oPrint:Say (_nLin,1190,"Qtde"     ,oFont8n )
		oPrint:Say (_nLin,1340,"Un.M"     ,oFont8n )
		oPrint:Say (_nLin,1427,"Qtd 2aUM",oFont8n )
		oPrint:Say (_nLin,1585,"2a.UM"    ,oFont8n )
		oPrint:Say (_nLin,1690,"Vlr Uni." ,oFont8n )
		oPrint:Say (_nLin,1870,"Vlr Total",oFont8n )
		oPrint:Say (_nLin,2100,"Vlr Bruto",oFont8n )
		oPrint:Line(_nLin-25,0100,_nLin+050,0100)
		oPrint:Line(_nLin-25,0250,_nLin+050,0250)
		oPrint:Line(_nLin-25,0450,_nLin+050,0450)
		oPrint:Line(_nLin-25,0650,_nLin+050,0650)
		oPrint:Line(_nLin-25,0850,_nLin+050,0850)
		oPrint:Line(_nLin-25,1150,_nLin+050,1150)
		oPrint:Line(_nLin-25,1320,_nLin+050,1320)
		oPrint:Line(_nLin-25,1420,_nLin+050,1420)
		oPrint:Line(_nLin-25,1570,_nLin+050,1570)
		oPrint:Line(_nLin-25,1670,_nLin+050,1670)
		oPrint:Line(_nLin-25,1800,_nLin+050,1800)
		oPrint:Line(_nLin-25,2050,_nLin+050,2050)
		oPrint:Line(_nLin-25,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=50
		
		While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cProd==(_cAliasSD1)->D1_COD
			//imprime cabecalho
			If _nLin>2940
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,5,.T.)
			EndIf
			
			
			oPrint:Say  (_nLin,0120,DToC(SToD((_cAliasSD1)->D1_DTDIGIT)),oFont8 )
			oPrint:Say  (_nLin,0270,(_cAliasSD1)->D1_DOC+"-"+(_cAliasSD1)->D1_SERIE,oFont8 )
			If AllTrim((_cAliasSD1)->D1_NFORI)<>'.'
				oPrint:Say  (_nLin,0470,(_cAliasSD1)->D1_NFORI+"-"+(_cAliasSD1)->D1_SERIORI,oFont8 )
			EndIf
			oPrint:Say  (_nLin,0670,(_cAliasSD1)->D1_FORNECE+"-"+(_cAliasSD1)->D1_LOJA,oFont8 )
			oPrint:Say  (_nLin,0870,SubStr((_cAliasSD1)->A1_NREDUZ,1,15) ,oFont8 )
			oPrint:Say (_nLin,1177,transform((_cAliasSD1)->D1_QUANT  ,"@re 999,999.99")   ,oFont8 )
			oPrint:Say (_nLin,1340,(_cAliasSD1)->D1_UM      ,oFont8 )
			oPrint:Say (_nLin,1435,transform((_cAliasSD1)->D1_QTSEGUM,"@re 999,999.99") ,oFont8 )
			oPrint:Say (_nLin,1590,(_cAliasSD1)->D1_SEGUM   ,oFont8 )
			oPrint:Say (_nLin,1650,transform((_cAliasSD1)->D1_TOTAL / (_cAliasSD1)->D1_QUANT ,"@re 999,999,999.99")  ,oFont8 )
			oPrint:Say (_nLin,1830,transform((_cAliasSD1)->D1_TOTAL ,"@re 999,999,999.99")  ,oFont8 )
			oPrint:Say (_nLin,2080,transform((_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA ,"@re 999,999,999.99")  ,oFont8 )//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
			_nTFQtd1+=(_cAliasSD1)->D1_QUANT
			_nTFQtd2+=(_cAliasSD1)->D1_QTSEGUM
			_nTFVlr +=(_cAliasSD1)->D1_TOTAL
			_nTFBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
			_nTPQtd1+=(_cAliasSD1)->D1_QUANT
			_nTPQtd2+=(_cAliasSD1)->D1_QTSEGUM
			_nTPVlr +=(_cAliasSD1)->D1_TOTAL
			_nTPBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
			_nTQtd1 +=(_cAliasSD1)->D1_QUANT
			_nTQtd2 +=(_cAliasSD1)->D1_QTSEGUM
			_nTVlr  +=(_cAliasSD1)->D1_TOTAL
			_nTBrt  +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA//Alteração - Talita Teixeira - 25/02/14 - Incluido o campo D1_DESPESA no valor bruto do pedido para correção da divergencia causada por esses valores. Conforme solicitado no chamado:5556
			oPrint:Line(_nLin-30,0100,_nLin+050,0100)
			oPrint:Line(_nLin-30,0250,_nLin+050,0250)
			oPrint:Line(_nLin-30,0450,_nLin+050,0450)
			oPrint:Line(_nLin-30,0650,_nLin+050,0650)
			oPrint:Line(_nLin-30,0850,_nLin+050,0850)
			oPrint:Line(_nLin-30,1150,_nLin+050,1150)
			oPrint:Line(_nLin-30,1320,_nLin+050,1320)
			oPrint:Line(_nLin-30,1420,_nLin+050,1420)
			oPrint:Line(_nLin-30,1570,_nLin+050,1570)
			oPrint:Line(_nLin-30,1670,_nLin+050,1670)
			oPrint:Line(_nLin-30,1800,_nLin+050,1800)
			oPrint:Line(_nLin-30,2050,_nLin+050,2050)
			oPrint:Line(_nLin-30,2300,_nLin+050,2300)
			oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=050
			(_cAliasSD1)->(DBSkip())
		End
		oPrint:Box (_nLin-050,0100,_nLin+100,2300)
		//oPrint:Say (_nLin+40,0120,"Subtotal produto: "+_cProd+"-"+SB1->B1_DESC ,oFont10 )
		oPrint:Say (_nLin+40,0120,"Subtotal produto: "+_cProd+"-"+SubStr(SB1->B1_DESC,1,52) ,oFont10 ) //GUILHERME 23/11/2012 - LIMITE DE IMPRESSAO DESC PRODUTO
		oPrint:Say (_nLin+50,1180,transform(_nTPQtd1,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,1435,transform(_nTPQtd2,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,1830,transform(_nTPVlr ,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,2080,transform(_nTPBrt   ,"@re 999,999,999.99")  ,oFont8 )
		//oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=150
		//imprime cabecalho
		If _nLin>2900
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,5,.T.)
		EndIf
		
	End
	oPrint:Box (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFont10 )
	oPrint:Say (_nLin,1180,transform(_nTFQtd1,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1435,transform(_nTFQtd2,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1830,transform(_nTFVlr ,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,2080,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFont8 )
	//oPrint:Line(_nLin+050,0100,_nLin+050,2300)
	_nLin+=150
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,5,.T.)
	EndIf
	
End


oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFont10 )
oPrint:Say (_nLin,1180,transform(_nTQtd1,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,1435,transform(_nTQtd2,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,1830,transform(_nTVlr ,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,2080,transform(_nTBrt ,"@re 999,999,999.99")  ,oFont8 )

oPrint:EndPage() // Finaliza a página

Return      

/*
===============================================================================================================================
Programa----------: ROMS009I6
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel por imprimir por Rede/Analitico   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009I6(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cGrupo  := " " As Char
Local _cNomFil := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTGQtd1 := 0 As Numeric
Local _nTGQtd2 := 0 As Numeric
Local _nTGVlr  := 0 As Numeric
Local _nTGBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric

oPrint:StartPage()   // Inicia uma nova página
ROMS009M(oPrint,6,.T.)

DBSelectArea(_cAliasSD1)
While ! Eof()
	
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,6,.T.)
	EndIf
	
	// Quebra por filial
	_cFilial:=(_cAliasSD1)->D1_FILIAL
	_nTFQtd1:=0
	_nTFQtd2:=0
	_nTFVlr :=0
	_nTFBrt :=0
	
	DBSelectArea("SM0")
	_nRecno:=Recno()
	LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
	_cNomFil:=SM0->M0_FILIAL
	oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFont8n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFont8 )
	oPrint:Say  (_nLin    ,0370,"Filial"       ,oFont8n )
	oPrint:Say  (_nLin+050,0370,_cNomFil,oFont8 )
	_nLin+=150
	DBGoTo(_nRecno)
	DBSelectArea(_cAliasSD1)
	
	While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,6,.T.)
		EndIf
		
		// Quebra por grupo de vendas
		_cGrupo :=(_cAliasSD1)->A1_GRPVEN
		_nTGQtd1:=0
		_nTGQtd2:=0
		_nTGVlr :=0
		_nTGBrt :=0
		                           
		ACY->(DBSeek(xFilial("ACY")+_cGrupo))
		oPrint:Say  (_nLin    ,0120,"Grupo de vendas" ,oFont8n )
		oPrint:Say  (_nLin+050,0120,_cGrupo			,oFont8 )
		oPrint:Say  (_nLin    ,0400,"Descrição"  ,oFont8n )
		oPrint:Say  (_nLin+050,0400,ACY->ACY_DESCRI,oFont8 )
		oPrint:Line(_nLin-50,0100,_nLin+100,0100)
		oPrint:Line(_nLin-50,2300,_nLin+100,2300)
		oPrint:Line (_nLin+100,0100,_nLin+100,2300)
		_nLin+=150
		
		oPrint:Say (_nLin,0120,"Dt.Entr."      ,oFont8n )
		oPrint:Say (_nLin,0230,"NFD-Serie"     ,oFont8n )
		oPrint:Say (_nLin,0400,"NF Ref-Serie"  ,oFont8n )     
		oPrint:Say (_nLin,0570,"Cliente-Loja"  ,oFont8n )
		oPrint:Say (_nLin,0720,"Nome"          ,oFont8n )    
		oPrint:Say (_nLin,0970,"Descrição"     ,oFont8n )    
		oPrint:Say (_nLin,1420,"Qtde"          ,oFont8n )
		oPrint:Say (_nLin,1570,"Un.M"          ,oFont8n )
		oPrint:Say (_nLin,1670,"Qtd 2aUM"      ,oFont8n )
		oPrint:Say (_nLin,1820,"2a.UM"         ,oFont8n )
		oPrint:Say (_nLin,1920,"Vlr Uni."      ,oFont8n )
		oPrint:Say (_nLin,2020,"Vlr Total"     ,oFont8n )
		oPrint:Say (_nLin,2170,"Vlr Bruto"     ,oFont8n )
		oPrint:Line(_nLin-45,0100,_nLin+050,0100)
		oPrint:Line(_nLin-45,0210,_nLin+050,0210)
		oPrint:Line(_nLin-45,0380,_nLin+050,0380)
		oPrint:Line(_nLin-45,0550,_nLin+050,0550)
		oPrint:Line(_nLin-45,0700,_nLin+050,0700)
		oPrint:Line(_nLin-45,0950,_nLin+050,0950)
		oPrint:Line(_nLin-45,1400,_nLin+050,1400)
		oPrint:Line(_nLin-45,1550,_nLin+050,1550)
		oPrint:Line(_nLin-45,1650,_nLin+050,1650)
		oPrint:Line(_nLin-45,1800,_nLin+050,1800)
		oPrint:Line(_nLin-45,1900,_nLin+050,1900)
		oPrint:Line(_nLin-45,2000,_nLin+050,2000)
		oPrint:Line(_nLin-45,2150,_nLin+050,2150)
		oPrint:Line(_nLin-45,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
		_nLin+=50
		
		While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cGrupo==(_cAliasSD1)->A1_GRPVEN
			//imprime cabecalho
			If _nLin>2940
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,6,.T.)
			EndIf
			           
			SB1->(DBSeek(xFilial("SB1")+(_cAliasSD1)->D1_COD))
			
			oPrint:Say  (_nLin,0120,DToC(SToD((_cAliasSD1)->D1_DTDIGIT)),oFont8 )
			oPrint:Say  (_nLin,0230,(_cAliasSD1)->D1_DOC+"-"+(_cAliasSD1)->D1_SERIE,oFont8 )
			If AllTrim((_cAliasSD1)->D1_NFORI)<>'.'
				oPrint:Say  (_nLin,0400,(_cAliasSD1)->D1_NFORI+"-"+(_cAliasSD1)->D1_SERIORI,oFont8 )
			EndIf
			oPrint:Say (_nLin,0570,(_cAliasSD1)->D1_FORNECE+"-"+(_cAliasSD1)->D1_LOJA ,oFont8 )
			oPrint:Say (_nLin,0720,SubStr((_cAliasSD1)->A1_NREDUZ,1,15)       ,oFont8 )         
			oPrint:Say (_nLin,0970,SubStr(SB1->B1_I_DESCD,1,35)       ,oFont8 ) 
			oPrint:Say (_nLin,1420,transform((_cAliasSD1)->D1_QUANT  ,"@re 999,999.99")   ,oFont8 )
			oPrint:Say (_nLin,1570,(_cAliasSD1)->D1_UM      ,oFont8 )
			oPrint:Say (_nLin,1670,transform((_cAliasSD1)->D1_QTSEGUM,"@re 999,999.99") ,oFont8 )
			oPrint:Say (_nLin,1820,(_cAliasSD1)->D1_SEGUM   ,oFont8 )
			oPrint:Say (_nLin,1920,transform((_cAliasSD1)->D1_TOTAL / (_cAliasSD1)->D1_QUANT ,"@re 999,999.99")  ,oFont8 )
			oPrint:Say (_nLin,2020,transform((_cAliasSD1)->D1_TOTAL ,"@re 99,999,999.99")  ,oFont8 )
			oPrint:Say (_nLin,2150,transform((_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET ,"@re 99,999,999.99")  ,oFont8 )
			_nTFQtd1+=(_cAliasSD1)->D1_QUANT
			_nTFQtd2+=(_cAliasSD1)->D1_QTSEGUM
			_nTFVlr +=(_cAliasSD1)->D1_TOTAL
			_nTFBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
			_nTGQtd1+=(_cAliasSD1)->D1_QUANT
			_nTGQtd2+=(_cAliasSD1)->D1_QTSEGUM
			_nTGVlr +=(_cAliasSD1)->D1_TOTAL
			_nTGBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
			_nTQtd1 +=(_cAliasSD1)->D1_QUANT
			_nTQtd2 +=(_cAliasSD1)->D1_QTSEGUM
			_nTVlr  +=(_cAliasSD1)->D1_TOTAL
			_nTBrt  +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
		oPrint:Line(_nLin-30,0100,_nLin+050,0100)
		oPrint:Line(_nLin-30,0210,_nLin+050,0210)
		oPrint:Line(_nLin-30,0380,_nLin+050,0380)
		oPrint:Line(_nLin-30,0550,_nLin+050,0550)
		oPrint:Line(_nLin-30,0700,_nLin+050,0700)
		oPrint:Line(_nLin-30,0950,_nLin+050,0950)
		oPrint:Line(_nLin-30,1400,_nLin+050,1400)
		oPrint:Line(_nLin-30,1550,_nLin+050,1550)
		oPrint:Line(_nLin-30,1650,_nLin+050,1650)
		oPrint:Line(_nLin-30,1800,_nLin+050,1800)
		oPrint:Line(_nLin-30,1900,_nLin+050,1900)
		oPrint:Line(_nLin-30,2000,_nLin+050,2000)
		oPrint:Line(_nLin-30,2150,_nLin+050,2150)
		oPrint:Line(_nLin-30,2300,_nLin+050,2300)
		oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=050
			(_cAliasSD1)->(DBSkip())
		End
		oPrint:Box (_nLin-050,0100,_nLin+100,2300)
		oPrint:Say (_nLin+40,0120,"Subtotal rede: "+_cGrupo+"-"+ACY->ACY_DESCRI ,oFont8 )
		oPrint:Say (_nLin+50,1420,transform(_nTGQtd1,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,1670,transform(_nTGQtd2,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,2020,transform(_nTGVlr ,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,2150,transform(_nTGBrt ,"@re 999,999,999.99") ,oFont8 )      

		_nLin+=150
		//imprime cabecalho
		If _nLin>2900
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,6,.T.)
		EndIf
		
	End
	oPrint:Box (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFont8 )
	oPrint:Say (_nLin,1420,transform(_nTFQtd1,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1670,transform(_nTFQtd2,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,2020,transform(_nTFVlr ,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,2150,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFont8 )

	_nLin+=150
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,6,.T.)
	EndIf
	
End


oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFont8 )
oPrint:Say (_nLin,1420,transform(_nTQtd1,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,1670,transform(_nTQtd2,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,2020,transform(_nTVlr ,"@re 999,999,999.99") ,oFont8 )           
oPrint:Say (_nLin,2150,transform(_nTBrt ,"@re 999,999,999.99")  ,oFont8 )

oPrint:EndPage() // Finaliza a página
	
Return   

/*
===============================================================================================================================
Programa----------: ROMS009I7
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel por imprimir por Cliente/Analitico          
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009I7(oPrint As Object) As Logical

Local _cFilial := " " As Char
Local _cGrupo  := " " As Char
Local _cCliente := " " As Char
Local _cNomFil := " " As Char
Local _nTFQtd1 := 0 As Numeric
Local _nTFQtd2 := 0 As Numeric
Local _nTFVlr  := 0 As Numeric
Local _nTFBrt  := 0 As Numeric
Local _nTGQtd1 := 0 As Numeric
Local _nTGQtd2 := 0 As Numeric
Local _nTGVlr  := 0 As Numeric
Local _nTGBrt  := 0 As Numeric
Local _nTCQtd1 := 0 As Numeric
Local _nTCQtd2 := 0 As Numeric
Local _nTCVlr  := 0 As Numeric
Local _nTCBrt  := 0 As Numeric
Local _nTQtd1  := 0 As Numeric
Local _nTQtd2  := 0 As Numeric
Local _nTVlr   := 0 As Numeric
Local _nTBrt   := 0 As Numeric

oPrint:StartPage()   // Inicia uma nova página
ROMS009M(oPrint,7,.T.)

DBSelectArea(_cAliasSD1)
While ! Eof()
	
	//imprime cabecalho
	If _nLin>2940
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,7,.T.)
	EndIf
	
	// Quebra por filial
	_cFilial:=(_cAliasSD1)->D1_FILIAL
	_nTFQtd1:=0
	_nTFQtd2:=0
	_nTFVlr :=0
	_nTFBrt :=0
	
	DBSelectArea("SM0")
	_nRecno:=Recno()
	LOCATE For AllTrim(M0_CODFIL)=(_cAliasSD1)->D1_FILIAL
	_cNomFil:=SM0->M0_FILIAL
	oPrint:Box  (_nLin-030,0100,_nLin+100,2300)
	oPrint:Say  (_nLin    ,0120,"Código"       ,oFont10n )
	oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FILIAL,oFont10 )
	oPrint:Say  (_nLin    ,0400,"Filial"       ,oFont10n )
	oPrint:Say  (_nLin+050,0400,_cNomFil,oFont10 )
	_nLin+=150
	DBGoTo(_nRecno)
	DBSelectArea(_cAliasSD1)
	
	While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL
		
		//imprime cabecalho
		If _nLin>2940
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,7,.T.)
		EndIf
		
		// Quebra por grupo de vendas
		_cGrupo :=(_cAliasSD1)->A1_GRPVEN
		_nTGQtd1:=0
		_nTGQtd2:=0
		_nTGVlr :=0
		_nTGBrt :=0
		
		ACY->(DBSeek(xFilial("ACY")+_cGrupo))
		oPrint:Say  (_nLin    ,0120,"Grupo de vendas" ,oFont10n )
		oPrint:Say  (_nLin+050,0120,_cGrupo			,oFont10 )
		oPrint:Say  (_nLin    ,0400,"Descrição"  ,oFont10n )
		oPrint:Say  (_nLin+050,0400,ACY->ACY_DESCRI,oFont10 )
		oPrint:Line(_nLin-50,0100,_nLin+100,0100)
		oPrint:Line(_nLin-50,2300,_nLin+100,2300)
		oPrint:Line (_nLin+100,0100,_nLin+100,2300)
		_nLin+=150
		
		
		While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. 	_cGrupo ==(_cAliasSD1)->A1_GRPVEN
			
			//imprime cabecalho
			If _nLin>2940
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,7,.T.)
			EndIf
			
			// Quebra por cliente
			_cCliente:=(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA
			_nTCQtd1:=0
			_nTCQtd2:=0
			_nTCVlr :=0
			_nTCBrt :=0
			
			SA1->(DBSeek(xFilial("SA1")+_cCliente))
			oPrint:Say  (_nLin    ,0120,"Código" ,oFont10n )
			oPrint:Say  (_nLin+050,0120,(_cAliasSD1)->D1_FORNECE ,oFont10 )
			oPrint:Say  (_nLin    ,0320,"Loja" ,oFont10n )
			oPrint:Say  (_nLin+050,0320,(_cAliasSD1)->D1_LOJA,oFont10 )
			oPrint:Say  (_nLin    ,0520,"Nome Fantasia"  ,oFont10n )
			oPrint:Say  (_nLin+050,0520,SubStr(SA1->A1_NREDUZ,1,15),oFont10 )
			oPrint:Say  (_nLin    ,0920,"Razão Social"  ,oFont10n )
			oPrint:Say  (_nLin+050,0920,SubStr(SA1->A1_NOME,1,30),oFont10 )
			oPrint:Say  (_nLin    ,1700,"Municipio"     ,oFont10n )
			oPrint:Say  (_nLin+050,1700,(_cAliasSD1)->A1_MUN   ,oFont10 )
			oPrint:Say  (_nLin    ,2150,"Estado"        ,oFont10n )
			oPrint:Say  (_nLin+050,2150,(_cAliasSD1)->A1_EST    ,oFont10 )
			oPrint:Line(_nLin-50,0100,_nLin+100,0100)
			oPrint:Line(_nLin-50,2300,_nLin+100,2300)
			oPrint:Line (_nLin+100,0100,_nLin+100,2300)
			_nLin+=150
			
			oPrint:Say (_nLin,0120,"Dt.Entr."      ,oFont8n )
			oPrint:Say (_nLin,0270,"NFD-Serie"     ,oFont8n )
			oPrint:Say (_nLin,0470,"NF Ref-Serie"  ,oFont8n )
			oPrint:Say (_nLin,0670,"Descrição"     ,oFont8n )
			oPrint:Say (_nLin,1290,"Qtde"          ,oFont8n )
			oPrint:Say (_nLin,1420,"Un.M"          ,oFont8n )
			oPrint:Say (_nLin,1520,"Qtd 2aUM"      ,oFont8n )
			oPrint:Say (_nLin,1670,"2a.UM"         ,oFont8n )
			oPrint:Say (_nLin,1770,"Vlr Uni."      ,oFont8n )
			oPrint:Say (_nLin,1870,"Vlr Total"     ,oFont8n )
			oPrint:Say (_nLin,2140,"Vlr Bruto"     ,oFont8n )
			oPrint:Line(_nLin-45,0100,_nLin+050,0100)
			oPrint:Line(_nLin-45,0250,_nLin+050,0250)
			oPrint:Line(_nLin-45,0450,_nLin+050,0450)
			oPrint:Line(_nLin-45,0650,_nLin+050,0650)
			oPrint:Line(_nLin-45,1250,_nLin+050,1250)
			oPrint:Line(_nLin-45,1400,_nLin+050,1400)
			oPrint:Line(_nLin-45,1500,_nLin+050,1500)
			oPrint:Line(_nLin-45,1650,_nLin+050,1650)
			oPrint:Line(_nLin-45,1750,_nLin+050,1750)
			oPrint:Line(_nLin-45,1850,_nLin+050,1850)
			oPrint:Line(_nLin-45,2050,_nLin+050,2050)  
			oPrint:Line(_nLin-45,2300,_nLin+050,2300)
			oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=50
			
			While ! Eof() .And. _cFilial==(_cAliasSD1)->D1_FILIAL .And. _cCliente==(_cAliasSD1)->D1_FORNECE+(_cAliasSD1)->D1_LOJA
				//imprime cabecalho
				If _nLin>2940
					oPrint:EndPage() // Finaliza a página
					_nPag++
					oPrint:StartPage()   // Inicia uma nova página
					ROMS009M(oPrint,7,.T.)
				EndIf
				
				SB1->(DBSeek(xFilial("SB1")+(_cAliasSD1)->D1_COD))
				
				oPrint:Say  (_nLin,0120,DToC(SToD((_cAliasSD1)->D1_DTDIGIT)),oFont8 )
				oPrint:Say  (_nLin,0270,(_cAliasSD1)->D1_DOC+"-"+(_cAliasSD1)->D1_SERIE,oFont8 )
				If AllTrim((_cAliasSD1)->D1_NFORI)<>'.'
					oPrint:Say  (_nLin,0470,(_cAliasSD1)->D1_NFORI+"-"+(_cAliasSD1)->D1_SERIORI,oFont8 )
				EndIf
				//oPrint:Say  (_nLin,0670,SB1->B1_I_DESCD          ,oFont8 )
				oPrint:Say (_nLin,0670,SubStr(SB1->B1_I_DESCD,1,52)          ,oFont8 ) 
				oPrint:Say (_nLin,1270,transform((_cAliasSD1)->D1_QUANT  ,"@re 99,999.99")   ,oFont8 )
				oPrint:Say (_nLin,1420,(_cAliasSD1)->D1_UM      ,oFont8 )
				oPrint:Say (_nLin,1520,transform((_cAliasSD1)->D1_QTSEGUM,"@re 99,999.99") ,oFont8 )
				oPrint:Say (_nLin,1670,(_cAliasSD1)->D1_SEGUM   ,oFont8 )
				oPrint:Say (_nLin,1750,transform((_cAliasSD1)->D1_TOTAL / (_cAliasSD1)->D1_QUANT ,"@re 999,999.99")  ,oFont8 )
				oPrint:Say (_nLin,1870,transform((_cAliasSD1)->D1_TOTAL ,"@re 99,999,999.99")  ,oFont8 )
				oPrint:Say (_nLin,2120,transform((_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA ,"@re 99,999,999.99")  ,oFont8 )
				_nTFQtd1+=(_cAliasSD1)->D1_QUANT
				_nTFQtd2+=(_cAliasSD1)->D1_QTSEGUM
				_nTFVlr +=(_cAliasSD1)->D1_TOTAL
				_nTFBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
				_nTGQtd1+=(_cAliasSD1)->D1_QUANT
				_nTGQtd2+=(_cAliasSD1)->D1_QTSEGUM
				_nTGVlr +=(_cAliasSD1)->D1_TOTAL
				_nTGBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
				_nTCQtd1+=(_cAliasSD1)->D1_QUANT
				_nTCQtd2+=(_cAliasSD1)->D1_QTSEGUM
				_nTCVlr +=(_cAliasSD1)->D1_TOTAL
				_nTCBrt +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
				_nTQtd1 +=(_cAliasSD1)->D1_QUANT
				_nTQtd2 +=(_cAliasSD1)->D1_QTSEGUM
				_nTVlr  +=(_cAliasSD1)->D1_TOTAL
				_nTBrt  +=(_cAliasSD1)->D1_TOTAL+(_cAliasSD1)->D1_ICMSRET+(_cAliasSD1)->D1_DESPESA
				oPrint:Line(_nLin-30,0100,_nLin+050,0100)
				oPrint:Line(_nLin-30,0250,_nLin+050,0250)
				oPrint:Line(_nLin-30,0450,_nLin+050,0450)
				oPrint:Line(_nLin-30,0650,_nLin+050,0650)
				oPrint:Line(_nLin-30,1250,_nLin+050,1250)
				oPrint:Line(_nLin-30,1400,_nLin+050,1400)
				oPrint:Line(_nLin-30,1500,_nLin+050,1500)
				oPrint:Line(_nLin-30,1650,_nLin+050,1650)
				oPrint:Line(_nLin-30,1750,_nLin+050,1750)
				oPrint:Line(_nLin-30,1850,_nLin+050,1850)
				oPrint:Line(_nLin-30,2050,_nLin+050,2050)
				oPrint:Line(_nLin-30,2300,_nLin+050,2300)
				oPrint:Line(_nLin+050,0100,_nLin+050,2300)
				
				_nLin+=050
				(_cAliasSD1)->(DBSkip())
			End
			oPrint:Box (_nLin-050,0100,_nLin+100,2300)
			oPrint:Say (_nLin+40,0120,"Subtotal cliente: "+SA1->A1_COD+"-"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NREDUZ) ,oFont10 )
			oPrint:Say (_nLin+50,1270,transform(_nTCQtd1,"@re 999,999.99") ,oFont8 )
			oPrint:Say (_nLin+50,1520,transform(_nTCQtd2,"@re 99,999.99") ,oFont8 )
			oPrint:Say (_nLin+50,1870,transform(_nTCVlr ,"@re 99,999,999.99") ,oFont8 )
			oPrint:Say (_nLin+50,2120,transform(_nTCBrt ,"@re 99,999,999.99")  ,oFont8 )
			
			//oPrint:Line(_nLin+050,0100,_nLin+050,2300)
			_nLin+=150
			//imprime cabecalho
			If _nLin>2900
				oPrint:EndPage() // Finaliza a página
				_nPag++
				oPrint:StartPage()   // Inicia uma nova página
				ROMS009M(oPrint,7,.T.)
			EndIf
		End
		
		oPrint:Box (_nLin-050,0100,_nLin+100,2300)
		oPrint:Say (_nLin+40,0120,"Subtotal rede: "+_cGrupo+"-"+ACY->ACY_DESCRI ,oFont10 )
		oPrint:Say (_nLin+50,1270,transform(_nTGQtd1,"@re 999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,1520,transform(_nTGQtd2,"@re 999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,1870,transform(_nTGVlr ,"@re 999,999,999.99") ,oFont8 )
		oPrint:Say (_nLin+50,2120,transform(_nTGBrt   ,"@re 999,999,999.99")  ,oFont8 )

		_nLin+=150
		//imprime cabecalho
		If _nLin>2900
			oPrint:EndPage() // Finaliza a página
			_nPag++
			oPrint:StartPage()   // Inicia uma nova página
			ROMS009M(oPrint,7,.T.)
		EndIf
		
	End
	oPrint:Box (_nLin-050,0100,_nLin+050,2300)
	oPrint:Say (_nLin,0120,"Subtotal filial: "+_cFilial+"-"+_cNomFil ,oFont10 )
	oPrint:Say (_nLin,1270,transform(_nTFQtd1,"@re 999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1520,transform(_nTFQtd2,"@re 999,999.99") ,oFont8 )
	oPrint:Say (_nLin,1870,transform(_nTFVlr ,"@re 999,999,999.99") ,oFont8 )
	oPrint:Say (_nLin,2120,transform(_nTFBrt   ,"@re 999,999,999.99")  ,oFont8 )

	_nLin+=150
	//imprime cabecalho
	If _nLin>2900
		oPrint:EndPage() // Finaliza a página
		_nPag++
		oPrint:StartPage()   // Inicia uma nova página
		ROMS009M(oPrint,7,.T.)
	EndIf
	
End


oPrint:Box  (_nLin-50,0100,_nLin+100,2300)
oPrint:Say (_nLin,0120,"Total Geral: ",oFont10 )
oPrint:Say (_nLin,1270,transform(_nTQtd1,"@re 999,999.99") ,oFont8 )
oPrint:Say (_nLin,1520,transform(_nTQtd2,"@re 999,999.99") ,oFont8 )
oPrint:Say (_nLin,1870,transform(_nTVlr ,"@re 999,999,999.99") ,oFont8 )
oPrint:Say (_nLin,2120,transform(_nTBrt ,"@re 999,999,999.99")  ,oFont8 )

oPrint:EndPage() // Finaliza a página
	
Return   

/*
===============================================================================================================================
Programa----------: ROMS009I2
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao renponsavel pela parametrizacao do TMSPrinter
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
User Function ROMS009C() As Logical
Local oPrint As Object
oPrint:= TMSPrinter():New( "Relação " )
oPrint:SetPortrait() // ou SetLandscape()
oPrint:Setup()   // setup de impressao
Return 

/*
===============================================================================================================================
Programa----------: ROMS009I2
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------:Funcao renponsavel pela montagem de pagina      
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS009M(oPrint As Object, _nOpc As Numeric, lPrintNrPg As Logical) As Logical
Private cBitmap := 'lgrl01.bmp' As Char

_nLin:=160                          
If _nOpc==1
   oPrint:Say(_nLin,0400,"RELACAO DE DEVOLUÇÕES - ORDEM DE EMISSÃO - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
ElseIf _nopc==2      
   oPrint:Say(_nLin,0500,"DEVOLUÇÕES - SINTÉTICO POR PRODUTO - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
ElseIf _nopc==3
   oPrint:Say(_nLin,0500,"DEVOLUÇÕES - SINTÉTICO POR REDE - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
ElseIf _nopc==4
   oPrint:Say(_nLin,0500,"DEVOLUÇÕES - SINTÉTICO POR CLIENTE - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
ElseIf _nopc==5
   oPrint:Say(_nLin,0500,"DEVOLUÇÕES - ANALÍTICO POR PRODUTO - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
ElseIf _nopc==6
   oPrint:Say(_nLin,0500,"DEVOLUÇÕES - ANALÍTICO POR REDE - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
ElseIf _nopc==7
   oPrint:Say(_nLin,0500,"DEVOLUÇÕES - ANALÍTICO POR CLIENTE - DE "+DToC(MV_PAR02)+" A "+DToC(MV_PAR03),oFont16n )
EndIf
oPrint:SayBitMap(_nLin-40,120,cBitMap,230,090)
oPrint:Say(_nLin-60,2000 ,"Dt.Emissão: "+DToC(dDatabase),oFont10n )


If lPrintNrPg
	oPrint:Say(_nLin-30,2000 ,"Página: "+StrZero(_nPag,3),oFont10n )  
		Else
			oPrint:Say(_nLin-30,2000 ,"SIGA\ROMS009",oFont10n ) 
			oPrint:Say(_nLin+60,120 ,"Empresa: " + AllTrim(SM0->M0_NOME) + '/'+ AllTrim(SM0->M0_FILIAL),oFont10n )
EndIf    	

oPrint:Box (100,0100,270 ,2300)
             
_nLin:=300

                           
Return

/*
===============================================================================================================================
Programa----------: ROMS009I2
Autor-------------: Jeovane
Data da Criacao---: 11/02/2009 
Descrição---------: Funcao criada para imprimir a pagina de parametros do relatorio em modo grafico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/    
Static Function ROMS009P(oPrint As Object) As Logical

Local nAux     := 1 As Numeric

_aDadosParam := {}
aAdd(_aDadosParam,{"01","Da Filial",MV_PAR01})
aAdd(_aDadosParam,{"02","De Emissao",DToC(MV_PAR02)})
aAdd(_aDadosParam,{"03","Ate Emissao",DToC(MV_PAR03)})
aAdd(_aDadosParam,{"04","De Dt.entrada",DToC(MV_PAR04)})
aAdd(_aDadosParam,{"05","Ate Dt.entrada",DToC(MV_PAR05)})
aAdd(_aDadosParam,{"06","De Produto",MV_PAR06})
aAdd(_aDadosParam,{"07","Ate Produto ",MV_PAR07})
aAdd(_aDadosParam,{"08","De Cliente",MV_PAR08})
aAdd(_aDadosParam,{"09","Loja ",MV_PAR09})
aAdd(_aDadosParam,{"10","Ate Cliente",MV_PAR10})
aAdd(_aDadosParam,{"11","Loja",MV_PAR11})
aAdd(_aDadosParam,{"12","Rede",MV_PAR12})
aAdd(_aDadosParam,{"13","Estado",MV_PAR13})
aAdd(_aDadosParam,{"14","Municipio",MV_PAR14})
aAdd(_aDadosParam,{"15","Vendedor",MV_PAR15})
aAdd(_aDadosParam,{"16","Supervisor",MV_PAR16})
aAdd(_aDadosParam,{"17","Grupo Produto",MV_PAR17})
aAdd(_aDadosParam,{"18","Produto Nivel 2",MV_PAR18})
aAdd(_aDadosParam,{"19","Produto Nivel 3",MV_PAR19})
aAdd(_aDadosParam,{"20","Produto Nivel 4",MV_PAR20})

If MV_PAR21 == 1
	_ctipo := "Gerou financeiro"
ElseIf MV_PAR21 == 2
	_ctipo := "Nao gerou"
Else
	_ctipo := "Ambas"
EndIf

aAdd(_aDadosParam,{"21","Tipo devolucao",_ctipo})

If MV_PAR22 == 1
	_crela := "Sintetico"
Else
	_crela := "Analítico"
EndIf

aAdd(_aDadosParam,{"22","Relatorio",_crela})
aAdd(_aDadosParam,{"23","De Dt.Faturamento inicial",DToC(MV_PAR23)})
aAdd(_aDadosParam,{"24","Ate Dt.Faturamento final",DToC(MV_PAR24)})

If MV_PAR25 == 1
	_cform := "Sim"
ElseIf MV_PAR25 == 2
	_cform := "Não"
Else
	_cform := "Ambas"
EndIf

aAdd(_aDadosParam,{"25","Formulario proprio",_cform})

If MV_PAR26 == 1
	_cordem := "Emissao"
ElseIf MV_PAR26 == 2
	_cordem := "Produto"
ElseIf MV_PAR26 == 3
	_cordem := "Rede"
Else
	_cordem := "Cliente"
EndIf

aAdd(_aDadosParam,{"26","Ordem",_cordem})

If MV_PAR27 == 1
	_cncc := "Ambas"
ElseIf MV_PAR27 == 2
	_cncc := "Sim"
Else
	_cncc := "Não"
EndIf

aAdd(_aDadosParam,{"27","NCC Compensadas",_cncc})
aAdd(_aDadosParam,{"28","Sub Grupo Produto",MV_PAR28})
aAdd(_aDadosParam,{"29","TES a Desconsiderar",MV_PAR29})

If MV_PAR30 == 1
	_csaida := "Impresso"
Else
	_csaida := "Excel"
EndIf

aAdd(_aDadosParam,{"30","Impresso ou Excel",_csaida})
aAdd(_aDadosParam,{"31","Armazem",MV_PAR31})

If MV_PAR32 == 1
	_cform := "Sim"
ElseIf MV_PAR32 == 2
	_cform := "Não"
Else
	_cform := "Ambas"
EndIf
aAdd(_aDadosParam,{"32","Considera SEDEX",_cform})


_nLin+= 120
     
For nAux:= 1  to Len(_aDadosParam)
	  	
	  		If _nLin > 2840
	  		
	  				oPrint:Box  (0300,0100,_nLin+100,2300)        
	  		
					oPrint:EndPage() // Finaliza a página
					oPrint:StartPage()   // Inicia uma nova página

					//Quebra de Pagina  
					If MV_PAR26==1 // emissao 
			   		// O parametro .F. eh para nao imprimir o numero da pagina quando For montar a tela de parametros	  
					   ROMS009M(oPrint,1,.F.)
					ElseIf MV_PAR26 == 2 .And. MV_PAR22 == 1 // Produto/sintetico 
					   ROMS009M(oPrint,2,.F.)
					ElseIf MV_PAR26 == 3 .And. MV_PAR22 == 1 // Rede/sintetico
					   ROMS009M(oPrint,3,.F.)
					ElseIf MV_PAR26 == 4 .And. MV_PAR22 == 1  // Cliente/sintetico
					   ROMS009M(oPrint,4,.F.)
					ElseIf MV_PAR26 == 2 .And. MV_PAR22 == 2 // Produto/analitico
					   ROMS009M(oPrint,5,.F.)	  
					ElseIf MV_PAR26 == 3 .And. MV_PAR22 == 2 // Rede/analitico
					   ROMS009M(oPrint,6,.F.)
					ElseIf MV_PAR26 == 4 .And. MV_PAR22 == 2  // Cliente/analitico
					   ROMS009M(oPrint,7,.F.)
					EndIf  
					
					_nLin+= 120  
			
			EndIf
				
	
		oPrint:Say (_nLin,0150  ,"Pergunta " + AllTrim(_aDadosParam[nAux,1]) + ' : ' + AllTrim(_aDadosParam[nAux,2]),oFont14n)       
		oPrint:Say (_nLin,0900  ,_aDadosParam[nAux,3],oFont14n) 
		
		_nLin+= 60	
	
Next

oPrint:Box  (0300,0100,_nLin+100,2300)	   
	
oPrint:EndPage()     // Finaliza a página

Return
