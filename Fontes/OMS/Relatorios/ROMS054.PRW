/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 15/05/2024 | Chamado 47071. Ajustes nas colunas de segunda unidade de medida.
Lucas Borges  | 09/10/2024 | Chamado 48465. Retirada manipulação do SX1
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  | 23/07/2025 | Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
Lucas Borges  | 24/07/2025 | Chamado 51529. Removida cópia do e-mail para sistema@italac.com.br pois não faz sentido
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TopConn.ch"             
#Include "TBICONN.CH"  

/*
===============================================================================================================================
Programa----------: ROMS054
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/11/2018
Descrição---------: Relatorio de cortes em pedidos - Chamado 27023
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS054()

Local oproc := nil
Private _cPerg     := "ROMS054"
Private _aLista    := {}
Private _aColXML   := {}
Private _aItalac_F3:= {}

Begin Sequence

   _cQrySX5 := " SELECT "
   _cQrySX5 += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
   _cQrySX5 += " FROM "+ RetSqlName("SX5") +" X5 "
   _cQrySX5 += " WHERE "
   _cQrySX5 += "     D_E_L_E_T_ = ' ' "
   _cQrySX5 += " AND X5_TABELA  = 'Z1' "
   _cQrySX5 += " ORDER BY X5_CHAVE "
   
   aAdd(_aItalac_F3,{"MV_PAR23" ,_cQrySX5 , {|Tab| (Tab)->CHAVE } , {|Tab| (Tab)->DESCRI} ,,"Motivos de Corte" ,          ,          ,20        ,.T.        ,       , } )

   If !Pergunte( _cPerg , .T. )
      BREAK
   EndIf
   lSair := .F.
   _cHoraInicial:=Time()
   FWMsgRun(,{|oproc| lSair:=ROMS054Ger(oproc) },"Hora Inicial: "+_cHoraInicial+", Aguarde...","Hora Inicial: "+_cHoraInicial+", Carregando histórico..." )

   If lSair
      If Len(_ALISTA) == 0
	     U_ITMsg("Não foram localizados registros","Atenção",,1)
	  EndIf
      BREAK
   EndIf

   aCab    :={}
   _aCabXML:={}
   ROMS054Col()//Preenche  o _aCabXML e aCab

    _cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+ "; Par. 2: " +AllTrim(AllToChar(MV_PAR02))+"; Par. 3: " +AllTrim(AllToChar(MV_PAR03))+"; Par. 4: "+AllTrim(AllToChar(MV_PAR04))+;
            "; Par. 5: "+AllTrim(AllToChar(MV_PAR05))+ "; Par. 6: " +AllTrim(AllToChar(MV_PAR06))+"; Par. 7: " +AllTrim(AllToChar(MV_PAR07))+"; Par. 8: "+AllTrim(AllToChar(MV_PAR08))+;
            "; Par. 9: "+AllTrim(AllToChar(MV_PAR09))+ "; Par. 10: "+AllTrim(AllToChar(MV_PAR10))+"; Par. 11: "+AllTrim(AllToChar(MV_PAR11))+;
            "; Par. 12: "+AllTrim(AllToChar(MV_PAR12))+"; Par. 13: "+AllTrim(AllToChar(MV_PAR13))+"; Par. 14: "+AllTrim(AllToChar(MV_PAR14))+;
            "; Par. 15: "+AllTrim(AllToChar(MV_PAR15))+"; Par. 16: "+AllTrim(AllToChar(MV_PAR16))+"; Par. 17: "+AllTrim(AllToChar(MV_PAR17))+;
            "; Par. 18: "+AllTrim(AllToChar(MV_PAR18))+"; Par. 19: "+AllTrim(AllToChar(MV_PAR19))+"; Par. 20: "+AllTrim(AllToChar(MV_PAR20))+;
            "; Par. 21: "+AllTrim(AllToChar(MV_PAR21))+"; Par. 22: "+AllTrim(AllToChar(MV_PAR22))+"; Par. 23: "+AllTrim(AllToChar(MV_PAR23))+;
            "; Par. 24: "+AllTrim(AllToChar(MV_PAR24))+"; Par. 25: "+AllTrim(AllToChar(MV_PAR25))+"; H.I.: "+_cHoraInicial+"; H.F.: "+Time()

                                                       //               ,_aCols ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab  , bDblClk , _aColXML , bCondMarca )
   lRet := U_ITListBox('Relatorio dos cortes em pedidos de vendas',aCab,_aLista, .T.     , 1    ,_cMsgTop,          ,        ,         ,     ,        ,          ,_aCabXML,         , _aColXML ,            )

End Sequence

Return 

/*
===============================================================================================================================
Programa----------: ROMS054Col
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
Descrição---------: Relatorio dde cortes em pedidos de venda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS054Col()
aCab    :={}
_aCabXML:={}
// Alinhamento: 1-Left   ,2-Center,3-Right
// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime

//          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
aAdd(aCab,"Data Corte")                     
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,4         ,.F.})// 01

aAdd(aCab,"Filial")                         
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 02

aAdd(aCab,"Mot Corte" )                
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 03

aAdd(aCab,"Nome Rede" )                
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 04

aAdd(aCab,"CNPJ"  )                     
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 05

aAdd(aCab,"Cod Loja"  )                
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 06

aAdd(aCab,"Nome Loja" )                
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 07

aAdd(aCab,"Estado" )                
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 08

aAdd(aCab,"Cond. Pagamento do Ped" )   
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 09

aAdd(aCab,"Filial Faturamento" )       
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 10

aAdd(aCab,"Pedido Protheus" )          
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 11

aAdd(aCab,"Pedido Portal")             
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 12

aAdd(aCab,"Armazém" )                  
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 13

aAdd(aCab,"Tp Operação")               
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 14

aAdd(aCab,"Pedido do Cliente")               
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 15

aAdd(aCab,"Cod Produto" )              
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 16

aAdd(aCab,"Desc Produto" )             
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 17

aAdd(aCab,"Qtd 1a unid" )              
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 18

aAdd(aCab,"Qtd 1a final")                 
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 19

aAdd(aCab,"1a unid")                  
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 20

aAdd(aCab,"Quant. Corte 1a unid")         
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 21

aAdd(aCab,"Qtd 2a unid" )              
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 22

aAdd(aCab,"Qtd 2a final")                 
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 23

aAdd(aCab,"2a. unid" )                 
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 24

aAdd(aCab,"Quant. Corte 2a unid" )          
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 25

aAdd(aCab,"Preço Bruto")               
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,3         ,.F.})// 26

aAdd(aCab,"Preço net" )                
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,3         ,.F.})// 27

aAdd(aCab,"Dt Entrada" )               
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,4         ,.F.})// 28

aAdd(aCab,"Dt Entrega" )               
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,4         ,.F.})// 29

aAdd(aCab,"Tp Agenda" )                
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 30

aAdd(aCab,"Tp Frete" )                 
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 31

aAdd(aCab,"Cidade"   )                 
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 32

aAdd(aCab,"Estado"  )                  
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 33

aAdd(aCab,"Peso Bruto"  )              
aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})// 34

aAdd(aCab,"Nome Gerente" )  		   
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 35

aAdd(aCab,"Nome Coord"  )              
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 36

aAdd(aCab,"Nome Superv"  )             
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 37

aAdd(aCab,"Nome Vend"  )               
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 38

aAdd(aCab,"Usuário"  )                 
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 39

aAdd(aCab,"Hora"  )                    
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 40

aAdd(aCab,"Desc Grp" )                 
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 41

aAdd(aCab,"Desc Sub Grp"  )            
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 42

aAdd(aCab,"Cod Familia"  )             
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 43

aAdd(aCab,"Desc Familia")              
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 44

aAdd(aCab,"Mix")                       
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 45

aAdd(aCab,"Motivo do Corte")           
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 46

aAdd(aCab,"Desc. Motivo do Corte")           
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 47

aAdd(aCab,"Codigo da Regiao")           
aAdd(_aCabXML,{aCab[Len(aCab)],2           ,1         ,.F.})// 48

aAdd(aCab,"Descricao da Regiao")           
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 49

aAdd(aCab,"CFOP")           
aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})// 50

Return aCab
/*
===============================================================================================================================
Programa----------: ROMS054Ger
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
Descrição---------: Executa relatório
Parametros--------: oproc - Objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS054Ger(oproc, _lScheduller)

Local _cQuery    := ""
Local cfiltro    := ""
Local L
Local _bUserN    := {|x| UsrFullName(x)}
Local cMix       := ""
Local _lImpDesm  := .T. // Imprime Desmembrados

Default _lScheduller := .F.

If _lScheduller 
	MV_PAR21 := 5
	MV_PAR18 := 1
	_lImpDesm := .T.//MOSTRAR NO SCHEDULE 
Else
	If MV_PAR24 = 1
		_lImpDesm  := .T. 
	Else
		_lImpDesm  := .F.
	EndIf 
EndIf

//================================================================================
// Filtra Filiais
//================================================================================
If !Empty(MV_PAR01)

	If Len(AllTrim(MV_PAR01)) < 5
		MV_PAR01:=LEFT(MV_PAR01,2)
		cFiltro += " AND Z07.Z07_IFILIA = '"+MV_PAR01+"' "
	Else
		cFiltro += " AND Z07.Z07_IFILIA IN " + FormatIn(AllTrim(MV_PAR01),";")
	EndIf

EndIf

//================================================================================
// Cliente De - Ate
//================================================================================
If !Empty( MV_PAR04 ) .And. !Empty( MV_PAR06 )
	cFiltro += " AND C5.C5_CLIENTE	BETWEEN '"+ MV_PAR04+"' AND '"+ MV_PAR06+"' "
EndIf

//================================================================================
// Loja De - Ate
//================================================================================
If !Empty( MV_PAR05 ) .And. !Empty( MV_PAR07 )
	cFiltro += " AND C5.C5_LOJACLI	BETWEEN '"+ MV_PAR05+"' AND '"+ MV_PAR07+"' "
EndIf

//================================================================================
// Rede
//================================================================================
If !Empty( MV_PAR08 )                                                   
	If Len(AllTrim(MV_PAR08)) <= 6
		cFiltro += " AND C5.C5_I_GRPVE	= '" + AllTrim(MV_PAR08) + "' "
	Else
		cFiltro += " AND C5.C5_I_GRPVE	IN " + FormatIn( MV_PAR08 , ";" )
	EndIf
EndIf

//================================================================================
// Estado
//================================================================================
If !Empty( MV_PAR09 )     
	If Len(AllTrim(MV_PAR09)) <= 2
		cFiltro  += " AND C5.C5_I_EST = '"+ AllTrim(MV_PAR09) + "' "
	Else
		cFiltro  += " AND C5.C5_I_EST IN "+ FormatIn( MV_PAR09 , ";" )
	EndIf
EndIf

//================================================================================
// Municipio
//================================================================================
If !Empty( MV_PAR10 )             
	If Len(AllTrim(MV_PAR10)) <= 6
		cFiltro  += " AND C5.C5_I_CMUN = '"+ AllTrim(MV_PAR10) + "' "
	Else
		cFiltro  += " AND C5.C5_I_CMUN	IN "+ FormatIn( MV_PAR10 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Coordenador
//================================================================================
If !Empty( MV_PAR11 )             
	If Len(AllTrim(MV_PAR11)) <= 6
		cFiltro += " AND C5.C5_VEND2 = '"+ AllTrim(MV_PAR11) + "' "
	Else
		cFiltro += " AND C5.C5_VEND2 IN "+ FormatIn( MV_PAR11 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Vendedor
//================================================================================
If !Empty( MV_PAR12 )      
	If Len(AllTrim(MV_PAR12)) <= 6
		cFiltro += " AND C5.C5_VEND1 = '"+ AllTrim(MV_PAR12) + "' "
	Else
		cFiltro += " AND C5.C5_VEND1 IN "+ FormatIn( MV_PAR12 , ";" )
	EndIf
EndIf

//================================================================================
// Tipo de agenda
//================================================================================
If !Empty( MV_PAR13 )                                                   
	If Len(AllTrim(MV_PAR13)) <= 1
		cFiltro += " AND C5.C5_I_AGEND	= '" + AllTrim(MV_PAR13) + "' "
	Else
		cFiltro += " AND C5.C5_I_AGEND	IN " + FormatIn( MV_PAR13 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra exclui Coordenador
//================================================================================
If !Empty( MV_PAR14 )             
	If Len(AllTrim(MV_PAR14)) <= 6
		cFiltro += " AND C5.C5_VEND2 != '"+ AllTrim(MV_PAR14) + "' "
	Else
		cFiltro += " AND C5.C5_VEND2 NOT IN "+ FormatIn( MV_PAR14 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Supervisor
//================================================================================
If !Empty( MV_PAR15 )      
	If Len(AllTrim(MV_PAR15)) <= 6
		cFiltro += " AND C5.C5_VEND4 = '"+ AllTrim(MV_PAR15) + "' "
	Else
		cFiltro += " AND C5.C5_VEND4 IN "+ FormatIn( MV_PAR15 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra operação
//================================================================================
If !Empty( MV_PAR17 )      
	If Len(AllTrim(MV_PAR17)) <= 2
		cFiltro += " AND C5.C5_I_OPER = '"+ AllTrim(MV_PAR17) + "' "
	Else
		cFiltro += " AND C5.C5_I_OPER IN "+ FormatIn( MV_PAR17 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra FATURADO
//================================================================================
If MV_PAR16 == 1
   cFiltro += " AND C5.C5_NOTA > ' ' "
ElseIf MV_PAR16 = 2
   cFiltro += " AND C5.C5_NOTA = ' ' "
EndIf
 
If MV_PAR18 <> 1 
   cFiltro += " AND C5.D_E_L_E_T_ = ' ' AND Z07.D_E_L_E_T_ = ' ' " 
EndIf


If !Empty( MV_PAR20 )
	cFiltro += " AND ZB9.ZB9_CODFAM = '"+ AllTrim(MV_PAR20) + "' "
EndIf


If !Empty(AllTrim(MV_PAR22)) 

	cFiltro += " AND C5.C5_VEND3 IN "+ FormatIn( MV_PAR22 , ";" )

EndIf

If !Empty(AllTrim(MV_PAR23)) 

   cFiltro += " AND Z07_IITEM IN "+ FormatIn( MV_PAR23 , ";" )

EndIf


//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("QRYPED") > 0
	QRYPED->( DBCloseArea() )
EndIf

//================================================================================
// Query para selecao dos dados DOS PEDIDOS
//================================================================================
_cQuery := "SELECT	DISTINCT C5.C5_FILIAL	, C5.C5_NUM		, C5.C5_CLIENTE	, C5.C5_LOJACLI ,  C5_I_BLCRE, "
_cQuery += "				 C5.C5_I_GRPVE	, C5.C5_I_NOMRD	, C5.C5_VEND1	, C5.C5_EMISSAO , C5.R_E_C_N_O_ C5REC, "
_cQuery += "				 C5.C5_I_PEDGE	, C5.C5_I_NPALE	, C5_I_PVREM    , C5_I_ENVRD    , C5_I_DTNEC         , C5_I_BLPRC, "
_cQuery += "				 C5.C5_I_FILFT	, C5.C5_I_FLFNC , C5_I_AGEND    , C5_I_PEVIN    , C5_I_PESBR         , C5_I_BLOQ, "  
_cQuery += "				 C5_I_TRCNF     , C5_I_PDFT     , C5_I_OPER     , C5_I_DTENT    , C5_LIBEROK         , C5_I_CEP, "
_cQuery += "				 C5_VEND3       , C5_VEND2      , C5_VEND3      , C5_I_DTENT    , C5_TPFRETE    	 , C5_VEND4           , C5_I_IDPED, C5_I_PODES, C5_I_PEDOR, "
_cQuery += "				 C5.C5_I_NOME   , C5.C5_I_EST   , C5.C5_I_V1NOM , C5.C5_I_MUN   , Z07_CAMPO          , Z07_CONORG         , Z07_CONALT, Z07_CODUSU,Z07_DATA,"
_cQuery += "                 Z07_HORA       , Z07_CHAVE     , Z07_OPCAO     , Z07_IITEM     , C5_CONDPAG         , Z07_INUM, "
_cQuery += "                 SC6.C6_PEDCLI  , C6_PRODUTO    , C6_QTDVEN     , C6_UNSVEN     , B1_TIPO            , B1_I_BIMIX         , ZB9_CODFAM         , Z07_ALIAS			 , SX5.X5_DESCRI , A1_NREDUZ, A1_EST , A1_CGC,      SA3.A3_NOME,     "

_cQuery += " 				 SA3_2.A3_NOME AS NOMESUP, SA3_2.A3_EMAIL AS EMAILSUP, "
_cQuery += "                 SA3_3.A3_NOME AS NOMEGER, SA3_3.A3_EMAIL AS EMAILGER, "
_cQuery += "                 SA3_4.A3_NOME AS NOMECOO, SA3_3.A3_EMAIL AS EMAILCOO, "
_cQuery += " 				 ZAM_REGCOD, SC6.C6_CF,"
_cQuery += " 				 SX5_2.X5_DESCRI AS ZAM_DESCRE"

_cQuery += "	FROM		 " + retsqlname("Z07") + " Z07 "   
_cQuery += "	   JOIN      " + retsqlname("SC5") + " C5  ON Z07.Z07_IFILIA = C5.C5_FILIAL AND Z07.Z07_INUM = C5.C5_NUM "  
_cQuery += "	   LEFT JOIN " + retsqlname("SC6") + " SC6 ON Z07.Z07_CHAVE = CONCAT(SC6.C6_FILIAL,CONCAT(SC6.C6_NUM,SC6.C6_ITEM)) "  
_cQuery += "	   LEFT JOIN " + retsqlname("SB1") + " SB1 ON SC6.C6_PRODUTO = SB1.B1_COD AND SB1.B1_FILIAL = '" + xFilial("SB1")+"' "  
_cQuery += "	   LEFT JOIN " + retsqlname("ZB9") + " ZB9 ON SB1.B1_I_SUBGR = ZB9.ZB9_SUBGRU AND ZB9.ZB9_FILIAL = '" + xFilial("ZB9")+"' "  
_cQuery += "	   LEFT JOIN " + retsqlname("SX5") + " SX5 ON SX5.X5_TABELA = 'Z1' AND SX5.X5_CHAVE = Z07.Z07_IITEM AND SX5.D_E_L_E_T_ = ' ' "  
_cQuery += "	   LEFT JOIN " + retsqlname("SA1") + " SA1 ON SA1.A1_COD = C5.C5_CLIENTE AND SA1.A1_LOJA = C5.C5_LOJACLI  AND SA1.A1_FILIAL = '" + xFilial("SA1")+"'  AND SA1.D_E_L_E_T_ = ' ' "  
_cQuery += "	   LEFT JOIN " + retsqlname("SA3") + " SA3 ON SA3.A3_COD = C5.C5_VEND1 AND SA3.A3_FILIAL = '" + xFilial("SA3")+"'  AND SA3.D_E_L_E_T_ = ' ' "  

_cQuery += " 	   LEFT JOIN " + RetSqlName("SA3") + " SA3_2 ON C5.C5_VEND4 = SA3_2.A3_COD AND SA3_2.D_E_L_E_T_ = ' ' "
_cQuery += " 	   LEFT JOIN " + RetSqlName("SA3") + " SA3_3 ON C5.C5_VEND3 = SA3_3.A3_COD AND SA3_3.D_E_L_E_T_ = ' ' "
_cQuery += " 	   LEFT JOIN " + RetSqlName("SA3") + " SA3_4 ON C5.C5_VEND2 = SA3_4.A3_COD AND SA3_4.D_E_L_E_T_ = ' ' "
_cQuery += " 	   LEFT JOIN " + RetSqlName("ZAM") + " ZAM ON ZAM.ZAM_COOCOD = C5.C5_VEND2 AND ZAM.ZAM_GERCOD = C5.C5_VEND3 AND ZAM.D_E_L_E_T_ = ' ' "
_cQuery += "	   LEFT JOIN " + retsqlname("SX5") + " SX5_2 ON SX5_2.X5_TABELA = 'ZC' AND ZAM.ZAM_REGCOD = SX5_2.X5_CHAVE AND  SX5_2.D_E_L_E_T_ = ' '  "  

_cQuery += " WHERE Z07.Z07_DATA	BETWEEN '"+ DToS(MV_PAR02)	+"' AND '"+ DToS(MV_PAR03)	+"' "  

_cQuery += "       AND ((Z07.Z07_ALIAS = 'SC5' AND Z07.Z07_CAMPO = 'C5_NUM    ') OR "
_cQuery += "            (Z07.Z07_ALIAS = 'SC6' AND Z07.Z07_CAMPO = 'C6_QTDVEN ' 

If !Empty( MV_PAR19 )
	_cQuery += "         AND SC6.C6_PRODUTO = '"+ AllTrim(MV_PAR19) + "' "
EndIf
cCfops:=""
If !Empty(MV_PAR25)//busca CFOPS de acordo com parametro definido por usuario	
	//Senao tiver escolhido 'A' opcao todos
	If !("A" $ MV_PAR25 )
		cCfops := U_ITCFOPS(MV_PAR25)
		cCfops := LEFT(cCfops,Len(cCfops)-1)
		cCfops := FormatIn(cCfops,";")
		_cQuery += "     AND SC6.C6_CF IN " + cCfops
	EndIf
EndIf
If MV_PAR21 <> 5 .And. !_lScheduller
	If MV_PAR21 = 1
		cMix := "G1"
	ElseIf MV_PAR21 = 2
		cMix := "G2"
	ElseIf MV_PAR21 = 3
		cMix := "G3"
	ElseIf MV_PAR21 = 4
		cMix := "G9"
	EndIf
	_cQuery += "         AND SB1.B1_I_BIMIX = '"+ cMix + "' "
EndIf
_cQuery += "             AND SB1.B1_TIPO = 'PA' "
_cQuery += "           )) "
_cQuery += "       AND ( (Z07.Z07_OPCAO = 'A' AND TO_NUMBER(TRIM(Z07_CONORG))  > TO_NUMBER(TRIM(Z07_CONALT))) OR Z07.Z07_OPCAO = 'E') "  
_cQuery += "       AND C5.C5_TIPO = 'N' "

_cQuery += cFiltro
 
_cQuery += "	ORDER BY Z07_INUM,Z07_DATA,Z07_HORA,C5_FILIAL "
 
If !_lScheduller
   oproc:cCaption := ("Carregando query de cortes...")
   ProcessMessages()
EndIf
TCQUERY _cQuery NEW ALIAS "QRYPED" 

_npv:=0
_nPVEx:=0
Z07->(DBSetOrder(3))

While QRYPED->(!Eof())
   
   If !_lScheduller
	  //Atualiza régua
	  oproc:cCaption := ("Lido itens Cortados: ["+ StrZero(_npv,8) +"],e itens Excluidos: ["+ StrZero(_nPVEx,8) +"] ")//de ["+ StrZero(nQtdTit,10) +"]")
	  ProcessMessages()
   EndIf
   
	_cDescricao := " "
	_cprod      := " "
	_carma      := " "
	_nprc       := 0
	_nprcnet    := 0	   
	
    //If !Empty(AllTrim(QRYPED->C6_PRODUTO))
    //    If QRYPED->B1_TIPO <> 'PA'
    //        QRYPED->(DBSkip())
    //        Loop
    //    EndIf
    //EndIf

	//Impressão de Desmembrados
	If !_lImpDesm
		If (QRYPED->Z07_ALIAS == 'SC5' .Or. QRYPED->Z07_ALIAS == 'SC6') .And. QRYPED->Z07_IITEM = '98'
			QRYPED->(DBSkip())
			Loop
		EndIf
	EndIf

	If QRYPED->Z07_OPCAO == 'A'
	
		SC6->(DBSetOrder(1))
		If SC6->(DBSeek(AllTrim(QRYPED->Z07_CHAVE)))
		               
			_cDescricao:= SC6->C6_DESCRI
			_cprod     := SC6->C6_PRODUTO
			_carma     := SC6->C6_LOCAL
			_nprc      := SC6->C6_PRCVEN
			aVlrDesc   := U_veriContrato( QRYPED->C5_CLIENTE , QRYPED->C5_LOJACLI , SC6->C6_PRODUTO )
			_nprcnet   :=  _nprc - ( ( aVlrDesc[1] * _nprc ) / 100 )
			
		Else
		
  			_cDescricao := "Item do PV não localizado"
			QRYPED->(DBSkip())
			Loop//SE NÃO ACHOU O ITEM É PQ VAI TER UMA OCORENCIA DE EXCLUISAO DO ITEM DEPOIS 
			
		EndIf	
	Else
	
		_cDescricao := "Item do PV não localizado"
		
	EndIf
    
	If _cDescricao == "Item do PV não localizado"
	
		//Localiza produto do log e prioriza produto que estava no mesmo movimento se possível
		Z07->(DBSetOrder(6))
		If Z07->(DBSeek(AllTrim(QRYPED->Z07_CHAVE)))
		
			While AllTrim(Z07->Z07_CHAVE) == AllTrim(QRYPED->Z07_CHAVE)
			
				If AllTrim(Z07->Z07_CAMPO) = 'C6_PRODUTO'

                    _cDescricao := Posicione("SB1",1,xFilial("SB1")+AllTrim(Z07->Z07_CONORG),"B1_DESC")
					_cprod      := SB1->B1_COD
					
				EndIf
				
				If AllTrim(Z07->Z07_CAMPO) = 'C6_LOCAL'
				
					_carma := AllTrim(Z07->Z07_CONORG) 
						
				EndIf
				
				If AllTrim(Z07->Z07_CAMPO) = 'C6_PRCVEN'
				
					_nprc := Val(AllTrim(Z07->Z07_CONORG)) 
					aVlrDesc	:= U_veriContrato( QRYPED->C5_CLIENTE , QRYPED->C5_LOJACLI , SB1->B1_COD )
					_nprcnet :=  _nprc - ( ( aVlrDesc[1] * _nprc ) / 100 )
						
				EndIf
			
				Z07->(DBSkip())
				
			EndDo
	
		EndIf
	
	EndIf

    If QRYPED->Z07_OPCAO == 'A' .And. Empty(_cprod) //SE For ALTERACAO E NAÃO ACHOU O CODIGO DO PRODUTO NO SC6 E NEM NO Z07 LE O SC6 DELETADO

         //================================================================================
         // Query para selecao dos dados DOS PEDIDOS deletados
         //================================================================================
         _cQuery := "SELECT MAX(C6.R_E_C_N_O_) RECSC6  "
         _cQuery += "	   FROM		" + retsqlname("SC6") + " C6   "
         _cQuery += " WHERE C6.C6_FILIAL  = '" + QRYPED->C5_FILIAL + "' "
         _cQuery += "   AND C6.C6_NUM     = '" + QRYPED->C5_NUM + "' "
         _cQuery += "   AND C6.D_E_L_E_T_ = '*' "
       	 _cQuery += " AND C6.C6_ITEM = '"+ RIGHT(AllTrim(QRYPED->Z07_CHAVE),2) + "' "
         _cQuery += " GROUP BY C6.C6_FILIAL, C6.C6_NUM , C6.C6_PRODUTO "
    
         TCQUERY _cQuery NEW ALIAS "QRYITEM"
         
		 If QRYITEM->(!Eof()) .And. QRYITEM->(!Bof())

            SC6->(DBGoTo( QRYITEM->RECSC6 ))
			_cDescricao:= SC6->C6_DESCRI
			_cprod     := SC6->C6_PRODUTO
			_carma     := SC6->C6_LOCAL
			_nprc      := SC6->C6_PRCVEN
			aVlrDesc   := U_veriContrato( QRYPED->C5_CLIENTE , QRYPED->C5_LOJACLI , SC6->C6_PRODUTO )
			_nprcnet   :=  _nprc - ( ( aVlrDesc[1] * _nprc ) / 100 )
		 
		 Else
			QRYPED->(DBSkip())
		    Loop   
		 EndIf
	
	EndIf

	//Calcula segunda unidade
	_nsegori := 0
	_nsegfim := 0
	
	If _cDescricao != "Item do PV não localizado"
	
		SB1->(DBSetOrder(1))
		If SB1->(DBSeek(xFilial("SB1")+_cprod))
		    
			_nFatConv:=SB1->B1_CONV
		    If _nFatConv = 0      
               _nFatConv := SB1->B1_I_FATCO//PARA QUANDO É QUEIJO PESO VARIADO
            EndIf 
	
			If _nFatConv > 0
			
				If SB1->B1_TIPCONV == "D"
				
					_nsegori := Val(QRYPED->Z07_CONORG) / _nFatConv
					_nsegfim := Val(QRYPED->Z07_CONALT) / _nFatConv
					
				Else
				
					_nsegori := Val(QRYPED->Z07_CONORG) * _nFatConv
					_nsegfim := Val(QRYPED->Z07_CONALT) * _nFatConv
					
				EndIf
            
			EndIf
	
		EndIf
	
	EndIf


	If !Empty(QRYPED->Z07_IITEM) .And.  ( QRYPED->Z07_OPCAO <> "E" )
		DBSelectArea("SX5")
		SX5->( DBSetOrder(1) )

		If SX5->( DBSeek( xFilial("SX5") + "Z1" + QRYPED->Z07_IITEM ) )
			_ccorte := SX5->X5_DESCRI
		Else
			_ccorte := "  "
		EndIf
	 
	ElseIf QRYPED->Z07_OPCAO == "E"
	
		If AllTrim(QRYPED->Z07_CAMPO) = "C5_NUM"
			_ccorte := "PV Excluido"		
		EndIf 
	
		If AllTrim(QRYPED->Z07_CAMPO) = "C6_QTDVEN" 
			_ccorte := "Produto excluído do Pedido"	//"Produto Excluido"	
		EndIf
	
	Else
	
		_ccorte := "  "
	
	EndIf

	//If ! Empty(QRYPED->C5_I_PODES)
	If (QRYPED->Z07_ALIAS == 'SC5' .Or. QRYPED->Z07_ALIAS == 'SC6') .And. QRYPED->Z07_IITEM = '98'
	   _ccorte := "Desmembramento de Pedido de Vendas"
	EndIf 
	
   If Val(QRYPED->Z07_CONORG) > Val(QRYPED->Z07_CONALT) .Or. ( (MV_PAR18 == 1) .And. QRYPED->Z07_OPCAO == 'E' .And. AllTrim(QRYPED->Z07_CONORG) == AllTrim(QRYPED->Z07_INUM))
	  
	  _cCondPagto  := Posicione("SE4",1,xFilial("SE4")+QRYPED->C5_CONDPAG, "E4_DESCRI")
	  
	  _nQtdCort1UN :=  Val(QRYPED->Z07_CONORG) - Val(QRYPED->Z07_CONALT)
	    
      _nQtdCort2CX := _NSEGORI - _NSEGFIM      
	  
	  _cCGCSA1:=Posicione("SA1",1,xFilial("SA1")+QRYPED->C5_CLIENTE+QRYPED->C5_LOJACLI,"A1_CGC")
	  If Len(AllTrim(_cCGCSA1)) = 14		
		 _cCGCSA1 := TRANSFORM(_cCGCSA1,"@R! NN.NNN.NNN/NNNN-99")	
	  ElseIf Len(AllTrim(_cCGCSA1)) = 11		
		 _cCGCSA1 := TRANSFORM(_cCGCSA1,"@R 999.999.999-99")
	  EndIf

      If _ccorte <> "PV Excluido"
      
	     ROMS54Lista(_alista)//Grava Itens cortados
	     _npv++
      
	  ElseIf _ccorte == "PV Excluido"

         If Select("QRYITEMPED") > 0
         	QRYITEMPED->( DBCloseArea() )
         EndIf

         //================================================================================
         // Query para selecao dos dados DOS PEDIDOS deletados
         //================================================================================
         _cQuery := "SELECT C6.C6_FILIAL, C6.C6_NUM, C6.C6_PRODUTO, MAX( C6.R_E_C_N_O_) RECSC6  "
         _cQuery += "	   FROM		" + retsqlname("SC6") + " C6   "
         _cQuery += " JOIN " + retsqlname("SB1") + " SB1 ON C6.C6_PRODUTO = SB1.B1_COD AND SB1.B1_FILIAL = '" + xFilial("SB1")+"' "  
         _cQuery += " WHERE C6.C6_FILIAL  = '" + QRYPED->C5_FILIAL + "' "
         _cQuery += "   AND C6.C6_NUM     = '" + QRYPED->C5_NUM + "' "
         _cQuery += "   AND C6.D_E_L_E_T_ = '*' "
         If !Empty( MV_PAR19 )
         	_cQuery += " AND C6.C6_PRODUTO = '"+ AllTrim(MV_PAR19) + "' "
         EndIf
         //busca CFOPS de acordo com parametro definido por usuario	
         If !Empty(MV_PAR25)
         	//Senao tiver escolhido 'A' opcao todos
         	If !("A" $ MV_PAR25 ) .And. !Empty( cCfops )
         		_cQuery += " AND C6.C6_CF IN " + cCfops
         	EndIf
         EndIf
         If MV_PAR21 <> 5 .And. !_lScheduller
         	If MV_PAR21 = 1
         		cMix := "G1"
         	ElseIf MV_PAR21 = 2
         		cMix := "G2"
         	ElseIf MV_PAR21 = 3
         		cMix := "G3"
         	ElseIf MV_PAR21 = 4
         		cMix := "G9"
         	EndIf
         	_cQuery += " AND SB1.B1_I_BIMIX = '"+ cMix + "' "
         EndIf
		 _cQuery += "    AND SB1.B1_TIPO = 'PA' "
         _cQuery += " GROUP BY C6.C6_FILIAL, C6.C6_NUM , C6.C6_PRODUTO "
         _cQuery += " ORDER BY C6.C6_FILIAL, C6.C6_NUM , C6.C6_PRODUTO "
    
         TCQUERY _cQuery NEW ALIAS "QRYITEMPED"
         //QRYITEMPED->(DBGoTop())

         //If QRYITEMPED->(!Eof())
         //   ROMS54Lista(_alista)//GRAVA A CAPA SC5 DOS EXCLUIDOS
		 //EndIf

         While QRYITEMPED->(!Eof())
                    
			SC6->(DBGoTo(QRYITEMPED->RECSC6))

			_nPVEx++
            If !_lScheduller
               oproc:cCaption := ("Lido itens Cortados: ["+ StrZero(_npv,8) +"],e itens Excluidos: ["+ StrZero(_nPVEx,8) +"] ")//de ["+ StrZero(nQtdTit,10) +"]")
               ProcessMessages()
            EndIf

            _cDescricao:= Posicione("SB1",1,xFilial("SB1")+AllTrim(SC6->C6_PRODUTO),"B1_DESC")
            _cprod     := SC6->C6_PRODUTO
            _carma     := SC6->C6_LOCAL
            _nprc      := SC6->C6_PRCVEN
            aVlrDesc   := U_veriContrato( QRYPED->C5_CLIENTE , QRYPED->C5_LOJACLI , SC6->C6_PRODUTO )
            _nprcnet   :=  _nprc - ( ( aVlrDesc[1] * _nprc ) / 100 )
            _ccorte    := "Pedido/Produto excluído totalmente"//"Produto Excluido (PVE)"					

            aAdd(_alista,{ SToD(QRYPED->Z07_DATA),;														    		// Data Corte            // 01 
    					 QRYPED->C5_FILIAL,;																	    // Filial                // 02 
    					 _ccorte,;   					                                                            // Mot Corte             // 03   -->9
    					 Posicione("ACY",1,xFilial("ACY")+QRYPED->C5_I_GRPVE,"ACY_DESCRI")  ,;				        // Nome Rede             // 04   -->3 
    					 _cCGCSA1,;                                                                            	    // CGC                   // 05    REMOVER 
    					 QRYPED->C5_CLIENTE + " / " + QRYPED->C5_LOJACLI  ,;                                        // Cod Loja              // 06    REMOVER
						 QRYPED->A1_NREDUZ,;                                                                        // RAZÃO SOCIAL          // 07     REMOVER
						 QRYPED->A1_EST,;                                                                           // Estado                // 08     REMOVER
    					 _cCondPagto,;								                                                // COND. PAGMENTO DO PED // 09   -->33          // Campo novo = Condição de pagamento.
    					 IIf(QRYPED->c5_i_trcnf == "S",QRYPED->c5_I_FILFT,QRYPED->c5_filial),;    	                // Filial Faturamento    // 10    REMOVER
    					 QRYPED->C5_NUM  ,;								                                            // Pedido Protheus       // 11   -->34 
    					 QRYPED->C5_I_IDPED  ,;															            // Pedido Portal         // 12    REMOVER
    					 _carma  ,;								                                                    // Armazém               // 13   -->35
    					 QRYPED->C5_I_OPER+"-"+Posicione("ZB4",1,xFilial("ZB4")+QRYPED->C5_I_OPER,"ZB4_DESCRI"),;   // Tp Operação           // 14    REMOVER
					 	 SC6->C6_PEDCLI,;                                                                           // Pedido do Cliente     // 15
    					 SB1->B1_COD  ,;				                                                            // Cod Produto           // 16   -->4 
    					 SB1->B1_DESC ,;			                                                                // Desc Produto          // 17   -->5
    					 SC6->C6_QTDVEN,; //Val(QRYPED->Z07_CONORG),;								                // Qtd 1a unid           // 18(*)-->6 //transform(Val(QRYPED->Z07_CONORG),"@E 999,999,999")
    					 0,; //If(QRYPED->Z07_OPCAO == 'A',Val(QRYPED->Z07_CONALT),0) ,;							// Qtd final             // 19(*)-->7 // IIf(QRYPED->Z07_OPCAO == 'A',transform(Val(QRYPED->Z07_CONALT),"@E 999,999,999"),"0")
    					 SB1->B1_UM  ,;																			    // 1a. Unid              // 20    REMOVER
    					 SC6->C6_QTDVEN,; //_nQtdCort1UN ,;									                        // Quant. Corte unid     // 21(*)-->38     // campo novo  = quantidade de corte
    					 SC6->C6_UNSVEN,;//If(QRYPED->Z07_OPCAO == 'A',_NSEGORI,0) 					,;              // Qtd 2a unid           // 22(*) REMOVER IIf(QRYPED->Z07_OPCAO == 'A',transform(_NSEGORI,"@E 999,999,999"),"0") ,;
    					 0,; //If(QRYPED->Z07_OPCAO == 'A',_NSEGFIM,0) 								,;	            // Qtd final             // 23(*)-->39    IIf(QRYPED->Z07_OPCAO == 'A',transform(_NSEGFIM,"@E 999,999,999"),"0") ,;
    					 SB1->B1_SEGUM  ,;																		    // 2a. Unid              // 24   -->40
    					 SC6->C6_UNSVEN,;//_nQtdCort2CX  ,;							                                // Quant. Corte cx       // 25(*)-->41     // campo novo = quantidade de corte
    					 _NPRC         ,;																	        // Preço Bruto           // 26(*)-->14 // transform(_NPRC   ,"@E 999,999,999.99")
    					 _NPRCNET      ,;																	        // Preço net             // 27(*)-->15 // transform(_NPRCNET,"@E 999,999,999.99")
    					 SToD(QRYPED->C5_EMISSAO)  ,;																// Dt Entrada            // 28   -->10
    					 SToD(QRYPED->C5_I_DTENT) ,;																// Dt Entrega            // 29   -->11
    					 U_TipoEntrega(QRYPED->C5_I_AGEND)  ,;														// Tp Agenda             // 30   -->29
    					 ROMS054C(QRYPED->C5_TPFRETE)   ,;			                                                // Tp Frete              // 31   -->16
    					 QRYPED->C5_I_MUN  ,;		                                                                // Cidade 	             // 32   -->17
    					 QRYPED->C5_I_EST  ,;																		// Estado                // 33   -->18
    					 QRYPED->C5_I_PESBR,; 								                                        // Peso Bruto            // 34(*)-->20 //transform(QRYPED->C5_I_PESBR,"@E 999,999,999")
						 QRYPED->NOMEGER  ,;                           												// Nome Gerente          // 35    -->21
						 QRYPED->NOMECOO  ,;                           												// Nome Coord            // 36    -->21	 Posicione("SA3",1,xFilial("SA3")+QRYPED->C5_VEND2,"A3_NOME")  ,;                           // Nome Coord            // 33-->21
						 QRYPED->NOMESUP  ,;																		// Nome Superv           // 37    -->22
						 QRYPED->A3_NOME  ,;																        // Nome Vend             // 38    -->24
    					 AllTrim(Eval(_bUserN,QRYPED->Z07_CODUSU)),;					                            // Usuário               // 39   -->25
    					 QRYPED->Z07_HORA  ,;							                                            // Hora                  // 40    REMOVER
    					 Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC"),;				                // Desc Grp              // 41   -->12
    					 Posicione("ZB9",1,xFilial("ZB9")+SB1->B1_I_SUBGR,"ZB9_DESSUB"),;	                        // Desc Sub Grp          // 42   -->13
    					 ZB9->ZB9_CODFAMI,;										                                    // Cod Familia           // 43   -->27
    					 Posicione("ZB3",1,xFilial("ZB3")+ZB9->ZB9_CODFAMI,"ZB3_DESFAMI"),;                         // Cod Familia           // 44
						 SB1->B1_I_BIMIX,; 		      	                                                            // MIX                   // 45
                         QRYPED->Z07_IITEM,;                                                                        // "Motivo do Corte      // 46 
						 QRYPED->X5_DESCRI,;                                                                        // Desc. Motivo do Corte // 47
						 QRYPED->ZAM_REGCOD,;                                                                       // Codigo da Regiao      // 48
						 QRYPED->ZAM_DESCRE,;                                                                       // Desc. Regiao          // 49
					     SC6->C6_CF })                                                                              // CFOP                  // 50

            QRYITEMPED->(DBSkip())
         EndDo

         If Select("QRYITEMPED") > 0
         	QRYITEMPED->( DBCloseArea() )
         EndIf
      EndIf
                
   EndIf
   
   QRYPED->(DBSkip())
	
EndDo   

_aColXML:=ACLONE(_aLista)//FORMATO PARA GERAR O EXCEL CORRETO EM INGLES COM PONTO

For L := 1 TO Len(_aLista)//AJUSTE PARA MOSTRA NA TELA DO U_ITListBox CORRETO

    _aLista[L,18]:= TRANSFORM(_aLista[L,18],"@E 999,999,999.999")// Qtd 1a unid           //  18 (*)
    _aLista[L,19]:= TRANSFORM(_aLista[L,19],"@E 999,999,999.999")// Qtd final             //  19 (*)
    _aLista[L,21]:= TRANSFORM(_aLista[L,21],"@E 999,999,999.999")// Quant. Corte unid     //  21 (*)
    _aLista[L,22]:= TRANSFORM(_aLista[L,22],"@E 999,999,999.999")// Qtd 2a unid           //  22 (*)
    _aLista[L,23]:= TRANSFORM(_aLista[L,23],"@E 999,999,999.999")// Qtd final             //  23 (*)
    _aLista[L,25]:= TRANSFORM(_aLista[L,25],"@E 999,999,999.999")// Quant. Corte cx       //  25 (*)
    _aLista[L,26]:= TRANSFORM(_aLista[L,26],"@E 999,999,999.99" )// Preço Bruto           //  26 (*)
    _aLista[L,27]:= TRANSFORM(_aLista[L,27],"@E 999,999,999.99" )// Preço net             //  27 (*)
    _aLista[L,34]:= TRANSFORM(_aLista[L,34],"@E 999,999,999.999")// Peso Bruto            //  34 (*)

Next

If Select("QRYPED") > 0
	QRYPED->( DBCloseArea() )
EndIf

If Select("QRYITEMPED") > 0
	QRYPRO->( DBCloseArea() )
EndIf

Return !Len(_aLista) > 0

/*
===============================================================================================================================
Programa----------: ROMS054U
Autor-------------: Josué Danich Prestes
Data da Criacao---: 28/11/2018
Descrição---------: Retorna nome do usuário dentro do Loop
Parametros--------: _ccod - código do usuário
Retorno-----------: _cnome - nome do usuário
===============================================================================================================================
*/
User Function ROMS054U(_ccod)

Local _cnome := usrretname(_ccod)

Return _cnome

/*
===============================================================================================================================
Programa----------: ROMS054C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 28/11/2018
Descrição---------: Retorna a descrição do tipo de frete
Parametros--------: _ccod - código do tipo de frete
Retorno-----------: _cnome - descrição do tipo de frete
===============================================================================================================================
*/
Static Function ROMS054C(_ccod)
If _ccod == "C"
	Return "CIF"
ElseIf _ccod == "F"
	Return "FOB"
ElseIf _ccod == "T"
	Return "Por conta terceiros"
ElseIf _ccod == "R"
	Return "Por conta remetente"
ElseIf _ccod == "D"
	Return "Por conta destinatário"
ElseIf _ccod == "S"
	Return "Sem frete"
EndIf
Return " "

/*
===============================================================================================================================
Programa----------: ROMS054E
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
Descrição---------: Envio por e-mail do Relatorio dde cortes em pedidos de venda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS054E()
Local _cQry
Local _nDiasPerCorte
Local _dDtInic, _dDtFinal
Local _cEmailCoord := ""
Local _cEmailGer   := ""
//Local _aCabec
Local _cNomeArq  := "" 
Local _cDirExcel := "\spool"
Local _cDataHora
Local _cTitulo
Local _cNomeGer, _cNomeCoord
Local _cfilial := "01"

Private _aLista

Begin Sequence

   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RESET ENVIRONMENT
   RpcSetType(3)
   
   //===========================================================================================
   // Preparando o ambiente com a filial da carga recebida
   //===========================================================================================
   PREPARE ENVIRONMENT EMPRESA '01' FILIAL _cfilial; //USER 'Administrador' PASSWORD '' ;
           TABLES "ZG7","ZG8","ZG0","SF1","SE2","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1","SA3";
           MODULO 'OMS'
   cFilAnt := _cfilial                                                                          

   _nDiasPerCorte := U_ITGETMV( 'IT_DIARCORT' , 30 )
   _dDtInic  := Date() - _nDiasPerCorte
   _dDtFinal := Date()
  
   MV_PAR01 := ""               // Filiais
   MV_PAR02 := _dDtInic         // Data de corte de
   MV_PAR03 := _dDtFinal        // Data corte ate 
   MV_PAR04 := Space(6)         // Cliente de
   MV_PAR05 := Space(4)         // Loja de
   MV_PAR06 := Space(6)         // Cliente ate
   MV_PAR07 := Space(4)         // Loja ate
   MV_PAR08 := Space(8)         // Rede
   MV_PAR09 := Space(2)         // Estado
   MV_PAR10 := Space(5)         // Municipio
   MV_PAR11 := Space(6)         // Coordenador
   MV_PAR12 := Space(6)         // Vendedor
   MV_PAR13 := Space(1)         // Tipo de agenda?
   MV_PAR14 := Space(6)         // Exclui Coord
   MV_PAR15 := Space(6)         // Supervisor
   MV_PAR16 := 3                // Somente Faturados?
   MV_PAR17 := Space(2)         // Operação
   MV_PAR18 := 2                // Exibe Pedidos Excluidos?
   //=============================================================================
   // Obtem dados dos coordenadores e gerentes para envio dos e-mails.
   //=============================================================================
   _cQry := "SELECT A3_COD, A3_GEREN, A3_EMAIL, A3_NOME FROM " + RETSQLNAME("SA3") + " SA3 "
   _cQry += " WHERE SA3.D_E_L_E_T_ = ' ' AND A3_I_TIPV = 'C' AND A3_MSBLQL = '2' " // A3_I_TIPV // V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR  
   _cQry += " ORDER BY A3_GEREN, A3_COD " 
   
   If Select("TRBSA3") > 0
	  TRBSA3->(DBCloseArea())
   EndIf
	
   TCQUERY _cQry NEW ALIAS "TRBSA3"	
   
   While ! TRBSA3->(Eof())
      _aLista      := {}   
	  _aColXML     := {}
       MV_PAR11    := TRBSA3->A3_COD  // Coordenador
      _cEmailCoord := TRBSA3->A3_EMAIL 
      _cEmailGer   := Posicione("SA3",1,xFilial("SA3")+TRBSA3->A3_GEREN,"A3_EMAIL") 
      _cNomeGer    := Posicione("SA3",1,xFilial("SA3")+TRBSA3->A3_GEREN,"A3_NOME")
      _cNomeCoord  := TRBSA3->A3_NOME
      
      //=================================================================
      // Gera os dados do relatório e preenche _aLista
      //=================================================================
      ROMS054Ger(, .T.)
 	      
      If Len(_aLista) > 0
         _aCabXML:={}
         ROMS054Col()//Preenche  o _aCabXML

         _cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
         _cNomeArq  := "CORTE_" + AllTrim(TRBSA3->A3_COD) + _cDataHora + ".xlsx"
         _cTitulo   := "Relatório de Corte de Pedidos de Vendas - Gerente: " + TRBSA3->A3_GEREN + " - Coordenador: " + TRBSA3->A3_COD
         //===============================================================
         // Gerando relatório em Excel para envio de e-mail
         //===============================================================
		 //           _cNomeArq,_cDiretorio,_cTitulo,_cNomePlan         ,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX
         U_ITGEREXCEL(_cNomeArq,_cDirExcel,_cTitulo,"Relatorio_de_Corte",_aCabXML   ,_aColXML ,.F.        ,          ,        ,.T.         ,            ,          ,            ,.T.  ) 

         If File(_cDirExcel+"\"+_cNomeArq) .And. U_ROMS054P(_cDirExcel+"\"+_cNomeArq)
            U_ROMS054R(TRBSA3->A3_COD, _cNomeCoord, _cEmailCoord, TRBSA3->A3_GEREN, _cNomeGer, _cEmailGer, _cDirExcel+"\"+_cNomeArq)            
         EndIf
         //===========================================================================
         // Exclui relatório Excel após envio de e-mail.
         //===========================================================================
         If File(_cDirExcel+"\"+_cNomeArq)
            FErase(_cDirExcel+"\"+_cNomeArq)
         EndIf

      EndIf      
      
      TRBSA3->(DBSkip())
   EndDo

End Sequence

Return

/*
===============================================================================================================================
Programa----------: ROMS054R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/02/2019
Descrição---------: Rotina de envio de e-mail para coordenador e gerente, com relatório em Excel anexo.
Parametros--------: _cCodCoord   = Codigo do Coordenador
                    _cNomeCoord  = Nome do Coordenador
                    _cEmailCoord = E-mail Coordenador
                    _cCodGer     = Codigo do gerente
                    _cNomeGer    = Nome do Gerente
                    _cEmailGer   = E-mail Gerente 
                    _cArqEnv     = Diretório + Nome do arquivo a ser enviado.
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function ROMS054R(_cCodCoord, _cNomeCoord, _cEmailCoord, _cCodGer, _cNomeGer, _cEmailGer, _cArqEnv)
Local _aConfig	:= U_ITCFGEML('') // Configurações do servidor de envio de e-mail.
Local _cHtml
Local _cAssunto
Local _cEmlLog := ""

Begin Sequence
   _cHtml := '<b>À '+ AllTrim(_cNomeCoord) +',</b>'
   _cHtml += '<br><br>'
   _cHtml += '&nbsp;&nbsp;&nbsp;Segue anexo o relatório de Corte do Pedito de Vendas do Coordenador: ' + AllTrim(_cCodCoord)  + "-" + AllTrim(_cNomeCoord)  +'.<br>'
   _cHtml += '<br>'
   _cHtml += '&nbsp;&nbsp;&nbsp;Em cópia segue Gerente: ' + AllTrim(_cCodGer) + "-" + AllTrim(_cNomeGer) + "."
   _cHtml += '<br><br>'
   _cHtml += '<b>Observação: </b>O arquivo em anexo deve ser aberto com o Microsoft Excel.'

   _cAssunto := "Relatório de Corte de Pedidos de Vendas, Coordenador: "+ AllTrim(_cCodCoord) + "-" + AllTrim(_cNomeCoord) + ", Gerente: " + AllTrim(_cCodGer) + "-" + AllTrim(_cNomeGer) +"."
 
    U_ITENVMAIL( "workflow@italac.com.br", _cEmailCoord, _cEmailGer ,, _cAssunto, _cHtml     , _cArqEnv, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
 
   _cEmlLog := Upper(_cEmlLog)
   
End Sequence

Return
 
/*
===============================================================================================================================
Programa----------: ROMS054P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/02/2019
Descrição---------: Realiza uma pausa e tenta abrir o arquivo passado por parâmetro para ver se já está disponível 
                    para ser enviado por e-mail.
Parametros--------: _cArqRelat = Arquivo de relatório a ser testado.
Retorno-----------: _lRet = .T. - arquivo aberto com sucesso.
                            .F. - não conseguiu abrir o arquivo.
===============================================================================================================================
*/

User Function ROMS054P(_cArqRelat)
Local _lRet := .F.
Local _nHandle
Local _nTempo := 0 , _nTempoTot := 30000

Begin Sequence
   While _nTempo <= _nTempoTot 
      // Abre o arquivon
      _nHandle := FT_FUse(_cArqRelat)
      
      If _nHandle <> -1  
         _lRet := .T.
         Break 
      EndIf
   
      _nTempo += 1000
      Sleep(1000)  // Faz uma pausa de 1 segundo.
   EndDo   

End Sequence

// Fecha o Arquivo
FT_FUSE()

Return _lRet

/*
===============================================================================================================================
Programa----------: ROMS54Lista
Autor-------------: Alex Wallauer
Data da Criacao---: 04/09/2023
Descrição---------: Grava a uma linha do _alista
Parametros--------: _alista
Retorno-----------: _alista
===============================================================================================================================
*/
Static Function ROMS54Lista(_alista)
Local _bUserN    := {|x| UsrFullName(x)}

      aAdd(_alista,{ SToD(QRYPED->Z07_DATA),;																	// Data Corte            // 01    
					 QRYPED->c5_filial,;																	    // Filial                // 02    
					 _ccorte,;   					                                                            // Mot Corte             // 03    -->9
					 Posicione("ACY",1,xFilial("ACY")+QRYPED->C5_I_GRPVE,"ACY_DESCRI")  ,;				        // Nome Rede             // 04    -->3 
					 _cCGCSA1,;                                                                            	    // CGC                   // 05     REMOVER 
					 QRYPED->C5_CLIENTE + " / " + QRYPED->C5_LOJACLI  ,;                                        // Cod Loja              // 06     REMOVER
					 QRYPED->A1_NREDUZ,;                                                                        // RAZÃO SOCIAL          // 07     REMOVER
					 QRYPED->A1_EST,;                                                                           // Estado                // 08     REMOVER
					 _cCondPagto,;								                                                // COND. PAGMENTO DO PED // 09    -->33          // Campo novo = Condição de pagamento.
					 IIf(QRYPED->c5_i_trcnf == "S",QRYPED->c5_I_FILFT,QRYPED->c5_filial),;    	                // Filial Faturamento    // 10     REMOVER
					 QRYPED->C5_NUM  ,;								                                            // Pedido Protheus       // 11    -->34 
					 QRYPED->C5_I_IDPED  ,;															            // Pedido Portal         // 12     REMOVER
					 _carma  ,;								                                                    // Armazém               // 13    -->35
					 QRYPED->C5_I_OPER+"-"+Posicione("ZB4",1,xFilial("ZB4")+QRYPED->C5_I_OPER,"ZB4_DESCRI"),;   // Tp Operação           // 14    REMOVER
					 QRYPED->C6_PEDCLI,;                                                                        // Pedido do Cliente     // 15
					 If(_ccorte == "PV Excluido","", _cprod   )  ,;				                                // Cod Produto           // 16    -->4 
					 If(_ccorte == "PV Excluido","", _cDescricao),;			                                    // Desc Produto          // 17    -->5
					 Val(QRYPED->Z07_CONORG),;	   		                                                        // Qtd 1a unid           // 18(*) -->6 //transform(Val(QRYPED->Z07_CONORG),"@E 999,999,999")
					 If(QRYPED->Z07_OPCAO == 'A',Val(QRYPED->Z07_CONALT),0) ,;                                  // Qtd final             // 19(*) -->7 // IIf(QRYPED->Z07_OPCAO == 'A',transform(Val(QRYPED->Z07_CONALT),"@E 999,999,999"),"0") 
					 If(_ccorte == "PV Excluido","", SB1->B1_UM)  ,;										    // 1a. Unid              // 20     REMOVER
					 _nQtdCort1UN  ,;									                                        // Quant. Corte unid     // 21(*) -->38     // campo novo  = quantidade de corte
					 _NSEGORI      ,;                                                                           // Qtd 2a unid           // 22(*)  REMOVER  // IIf(QRYPED->Z07_OPCAO == 'A',transform(_NSEGORI,"@E 999,999,999"),"0") // If(QRYPED->Z07_OPCAO == 'A',_NSEGORI,0)
					 _NSEGFIM      ,;                                                       	                // Qtd final             // 23(*) -->39     // IIf(QRYPED->Z07_OPCAO == 'A',transform(_NSEGFIM,"@E 999,999,999"),"0") // If(QRYPED->Z07_OPCAO == 'A',_NSEGFIM,0)
					 If(_ccorte == "PV Excluido","", SB1->B1_SEGUM),;										    // 2a. Unid              // 24    -->40 
					 _nQtdCort2CX  ,;							                                                // Quant. Corte cx       // 25(*) -->41 // campo novo = quantidade de corte
					 _NPRC         ,;	                        										        // Preço Bruto           // 26(*) -->14 //transform(_NPRC,"@E 999,999,999.99")  ,
					 _NPRCNET      ,;   	                        									        // Preço net             // 27(*) -->15 //transform(_NPRCNET,"@E 999,999,999.99")
					 SToD(QRYPED->C5_EMISSAO)  ,;																// Dt Entrada            // 28    -->10
					 SToD(QRYPED->C5_I_DTENT) ,;																// Dt Entrega            // 29    -->11
					 U_TipoEntrega(QRYPED->C5_I_AGEND)  ,;														// Tp Agenda             // 30    -->29
					 ROMS054C(QRYPED->C5_TPFRETE)   ,;			                                                // Tp Frete              // 31    -->16
					 QRYPED->C5_I_MUN  ,;		                                                                // Cidade 	             // 32    -->17
					 QRYPED->C5_I_EST  ,;																		// Estado                // 33    -->18
					 QRYPED->C5_I_PESBR,;                                                                       // Peso Bruto            // 34(*) -->20 //transform(QRYPED->C5_I_PESBR,"@E 999,999,999") 
					 QRYPED->NOMEGER  ,;                           												// Nome Gerente          // 35    -->21
					 QRYPED->NOMECOO  ,;                           												// Nome Coord            // 36    -->21	 Posicione("SA3",1,xFilial("SA3")+QRYPED->C5_VEND2,"A3_NOME")  ,;                           // Nome Coord            // 33-->21
					 QRYPED->NOMESUP  ,;																		// Nome Superv           // 37    -->22
					 QRYPED->A3_NOME  ,;																        // Nome Vend             // 38    -->24
					 AllTrim(Eval(_bUserN,QRYPED->Z07_CODUSU)),;					                            // Usuário               // 39    -->25
					 QRYPED->Z07_HORA  ,;							                                            // Hora                  // 40     REMOVER
					 If(_ccorte="PV Excluido","",Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")),;	    // Desc Grp              // 41    -->12
				     If(_ccorte="PV Excluido","",Posicione("ZB9",1,xFilial("ZB9")+SB1->B1_I_SUBGR,"ZB9_DESSUB")),;  // Desc Sub Grp          // 42    -->13
					 If(_ccorte="PV Excluido","",ZB9->ZB9_CODFAMI),;		                                        // Cod Familia           // 43    -->27
					 If(_ccorte="PV Excluido","",Posicione("ZB3",1,xFilial("ZB3")+ZB9->ZB9_CODFAMI,"ZB3_DESFAMI")),;// Desc Familia          // 44    -->26
					 QRYPED->B1_I_BIMIX,;                                                                           // Mix                   // 45   
                     QRYPED->Z07_IITEM,;                                                                            // Motivo do Corte       // 46 
					 QRYPED->X5_DESCRI,;                                                                            // Desc. Motivo do Corte // 47
					 QRYPED->ZAM_REGCOD,;                                                                           // Codigo da Regiao      // 48
					 QRYPED->ZAM_DESCRE,;                                                                           // Desc. Regiao          // 49
					 QRYPED->C6_CF })                                                                               // CFOP                  // 50

Return _alista
