/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 15/09/2023 | Chamado 44503. Jerry. Tratamento para as novas colunas de segmento e Subsegmento.
Alex Wallauer | 18/01/2024 | Chamado 46101. Jerry. Correção do Tratamento para as novas colunas de segmento e Subsegmento.
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ROMS019
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Relatório gráfico para emitir a relação de coordenadores e seus respectivos vendedores.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS019()

Private oFont10		:= TFont():New( "Courier New" ,, 08 ,, .F. ,,,, .T. , .F. )
Private oFont10b	:= TFont():New( "Courier New" ,, 08 ,, .T. ,,,, .T. , .F. )
Private oFont12		:= TFont():New( "Courier New" ,, 10 ,, .F. ,,,, .T. , .F. )
Private oFont12b	:= TFont():New( "Courier New" ,, 10 ,, .T. ,,,, .T. , .F. )
Private oFont14		:= TFont():New( "Courier New" ,, 12 ,, .F. ,,,, .T. , .F. )
Private oFont14b	:= TFont():New( "Courier New" ,, 12 ,, .T. ,,,, .T. , .F. )
Private oFont14Pr	:= TFont():New( "Courier New" ,, 12 ,, .T. ,,,, .T. , .F. )
Private oFont14Prb	:= TFont():New( "Courier New" ,, 12 ,, .T. ,,,, .T. , .F. )
Private oFont16b	:= TFont():New( "Helvetica"   ,, 14 ,, .T. ,,,, .T. , .F. )

Private oPrint		:= Nil

Private nPagina     := 0001
Private nLinha      := 0100
Private nLinhaInic  := 0100
Private nColInic    := 0030
Private nColFinal   := 3360
Private nqbrPagina  := 2200
Private nAjustAltu  := 0010
Private nLinInBox   := 0000
Private nSaltoLinha := 0050      

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)
Private _cPerg 		:= "ROMS019"
Private _aItalac_F3:={}

aAdd(_aItalac_F3,{"MV_PAR03"   ,"SA3"    ,2,3 ,{|| SA3->A3_I_TIPV ='S' },"Supervisores",Len(SA3->A3_COD),,16 } )

If !Pergunte( _cPerg )
	Aviso( 'Atenção!' , 'Operação cancelada pelo usuário!' , {'Fechar'} )
	Return
EndIf

If MV_PAR06 == 1
   _cTitulo := "Gerente X Coordenador"
ElseIf MV_PAR06 == 2
   _cTitulo := "Gerente X Coordenador X Supervisor"
ElseIf MV_PAR06 == 3
   _cTitulo := "Gerente X Coordenador X Supervisor X Vendedor"
Else
   _cTitulo := "Gerente X Coordenador X Supervisor X Vendedor X Clientes"
EndIf

If MV_PAR09 == 2  // Relatório impresso
   oPrint := TMSPrinter():New( _cTitulo )

   If MV_PAR06 == 4
      oPrint:SetLandscape() 	// Paisagem
   Else
      oPrint:SetPortrait() 	// Retrato
      nColFinal   := 2360
      nqbrPagina  := 3300
   EndIf

   oPrint:SetPaperSize(9)	// Seta para papel A4
   oPrint:StartPage() 

   ROMS019CAB( .F. )
   ROMS019PAR()
EndIf

cTimeInicial:=Time()

Processa( {|| ROMS019PRC() } , "Hora Inicial: "+cTimeInicial+' Aguarde!' , 'Iniciando o relatório...' )

If MV_PAR09 == 2  // Relatório impresso
   oPrint:EndPage() // Finaliza a Pagina.
   oPrint:Preview() // Visualiza antes de Imprimir.
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS019CAB
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o cabeçalho do relatório
Parametros--------: _lOpc : .T. = Imprime número da página / .F. = Não imprime número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS019CAB( _lOpc )

Local _cRaizSrv	:= IIf( IsSrvUnix() , "/" , "\" )
Local _cTitulo	:= "Relacao de "

If MV_PAR06 == 1
	_cTitulo += "Gerente X Coordenador"
ElseIf MV_PAR06 == 2
	_cTitulo += "Gerente X Coordenador X Supervisor"
ElseIf MV_PAR06 == 3
    _cTitulo += "Gerente X Coordenador X Supervisor X Vendedor"
Else
	_cTitulo += "Gerente X Coordenador X Supervisor X Vendedor X Clientes"
EndIf

nLinha := 0070

oPrint:SayBitmap( nLinha , nColInic , _cRaizSrv + "system/lgrl01.bmp" , 250 , 100 )

If _lOpc
	oPrint:Say( nlinha       , nColFinal - 550 , "PÁGINA: " + cValToChar( nPagina )                                   , oFont12b )
Else
	oPrint:Say( nlinha       , nColFinal - 550 , "SIGA/ROMS019"                                                       , oFont12b )
	oPrint:Say( nlinha + 100 , nColFinal - 550 , "EMPRESA: "+ AllTrim( SM0->M0_NOME ) +'/'+ AllTrim( SM0->M0_FILIAL ) , oFont12b )
EndIf

oPrint:Say(     nlinha + 050 , nColFinal - 550 , "DATA DE EMISSÃO: "+ DToC( Date() )                                  , oFont12b )

nlinha += ( nSaltoLinha * 3 )

oPrint:Say( nlinha , nColFinal / 2 , _cTitulo , oFont16b , nColFinal ,,, 2 )

nlinha += ( nSaltoLinha * 2 )

oPrint:Line( nLinha , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa----------: ROMS019CDD
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o cabeçalho de dados do relatório
Parametros--------: _lOpc : .T. = Imprime número da página / .F. = Não imprime número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019CDD()
                                                                            
oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , nColFinal } , oBrush )
oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal )

oPrint:Say( nlinha + nAjustAltu , nColInic + 0015 , "Cliente - Razão Social", oFont12b )
oPrint:Say( nlinha + nAjustAltu , nColInic + 0800 , "Nome Fantasia"			 , oFont12b )
oPrint:Say( nlinha + nAjustAltu , nColInic + 1220 , "CNPJ"						 , oFont12b ) // 1520
oPrint:Say( nlinha + nAjustAltu , nColInic + 1550 , "Rede"						 , oFont12b )  // 1850
oPrint:Say( nlinha + nAjustAltu , nColInic + 2050 , "UF"						    , oFont12b )     // 2350
oPrint:Say( nlinha + nAjustAltu , nColInic + 2120 , "Municipio"				 , oFont12b )  // 2420
oPrint:Say( nlinha + nAjustAltu , nColInic + 2480 , "Telefone"					 , oFont12b )    // 2780
oPrint:Say( nlinha + nAjustAltu , nColInic + 2730 , "Ult. Compra"				 , oFont12b )    // 3080

oPrint:Say( nlinha + nAjustAltu , nColInic + 2915 , "Limite Cred"		       , oFont12b )  // 3415
oPrint:Say( nlinha + nAjustAltu , nColInic + 3125 , "Prim. Compra"		    , oFont12b )  // 3715

oPrint:Line( nLinha , nColInic + 0795 , nLinha + nSaltoLinha , nColInic + 0795 ) //NOME FANTASIA
oPrint:Line( nLinha , nColInic + 1215 , nLinha + nSaltoLinha , nColInic + 1215 ) //CLIENTE   // 1515 
oPrint:Line( nLinha , nColInic + 1545 , nLinha + nSaltoLinha , nColInic + 1545 ) //CNPJ      // 1845
oPrint:Line( nLinha , nColInic + 2045 , nLinha + nSaltoLinha , nColInic + 2045 ) //UF          // 2345
oPrint:Line( nLinha , nColInic + 2115 , nLinha + nSaltoLinha , nColInic + 2115 ) //MUNICIPIO   // 2415
oPrint:Line( nLinha , nColInic + 2475 , nLinha + nSaltoLinha , nColInic + 2475 ) //TELEFONE    // 2775
oPrint:Line( nLinha , nColInic + 2725 , nLinha + nSaltoLinha , nColInic + 2725 ) //REDE       // 3075

oPrint:Line( nLinha , nColInic + 2910 , nLinha + nSaltoLinha , nColInic + 2910 ) //Limite de Credito   // 3410
oPrint:Line( nLinha , nColInic + 3120 , nLinha + nSaltoLinha , nColInic + 3120 ) //Primeira Compra     // 3795
nlinha += nSaltoLinha

Return

/*
===============================================================================================================================
Programa----------: ROMS019CSG
Autor-------------: Alexandre Villar
Data da Criacao---: 04/05/2015
Descrição---------: Imprime o cabeçalho de dados do Gerente no Relatório
Parametros--------: _lOpc : .T. = Imprime número da página / .F. = Não imprime número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019CSG( _cCodGer , _cDesGer )

oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , 2360 } , oBrush )
oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , 2360 )

If Empty( _cCodGer )
	oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , 'Gerente: 000000 - Não amarrado à um gerente' , oFont12b )
Else
	oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , 'Gerente: '+ SubStr( _cCodGer +' - '+ AllTrim( _cDesGer ) , 1 , 70 ) , oFont12b )
EndIf

nlinha += ( nSaltoLinha )

Return

/*
===============================================================================================================================
Programa----------: ROMS019CSC
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o cabeçalho de dados do Coordenador no relatório
Parametros--------: _cCodCoord = Codigo do Coordenador
                    _cDesCoord = Descrição do Coordenador
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019CSC( _cCodCoord , _cDesCoord)

oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , 2360 } , oBrush )
oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , 2360 )

If Empty(_cCodCoord)
	oPrint:Say( nlinha + nAjustAltu,nColInic + 15 , 'Coordenador: 000000 - Não amarrado à um coordenador' , oFont12b )
Else
	oPrint:Say( nlinha + nAjustAltu,nColInic + 15 , "Coordenador: "+ SubStr( _cCodCoord +' - '+ AllTrim( _cDesCoord ) , 1 , 70 ) , oFont12b )
EndIf

nlinha += ( nSaltoLinha )

Return

/*
===============================================================================================================================
Programa----------: ROMS019CSS
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o cabeçalho de dados do Supervisor no relatório
Parametros--------: _cCodSuper = Codigo do Supervisor
                    _cDesSuper = Descrição do Supervisor
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019CSS( _cCodSuper , _cDesSuper)

oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , 2360 } , oBrush )
oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , 2360 )

If Empty(_cCodSuper)
	oPrint:Say( nlinha + nAjustAltu,nColInic + 15 , 'Supervisor: 000000 - Não amarrado à um supervisor' , oFont12b )
Else
	oPrint:Say( nlinha + nAjustAltu,nColInic + 15 , "Supervisor: "+ SubStr( _cCodSuper +' - '+ AllTrim( _cDesSuper ) , 1 , 70 ) , oFont12b )
EndIf

nlinha += ( nSaltoLinha )

Return

/*
===============================================================================================================================
Programa----------: ROMS019CVN
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o cabeçalho de dados do Vendedor no relatório
Parametros--------: _lOpc : .T. = Imprime número da página / .F. = Não imprime número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019CVN( cCodVen , cDescVen )
                                                                            
oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , 2360 } , oBrush )
oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , 2360 )

oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , "Vendedor: "+ SubStr(cCodVen +' - '+ AllTrim(cDescVen) , 1 , 70 ) , oFont12b ) 

nlinha += ( nSaltoLinha * 2 )
nLinInBox := nlinha

Return

/*
===============================================================================================================================
Programa----------: ROMS019CLV
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o cabeçalho da lista de Vendedores no relatório
Parametros--------: _lOpc : .T. = Imprime número da página / .F. = Não imprime número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS019CLV( _nOpc )
Local _cSubTitulo

If _nOpc == 1 
   _cSubTitulo := 'Coordenador(es)' 
ElseIf _nOpc == 2
   _cSubTitulo := 'Vendedor(es)'
Else
   _cSubTitulo := 'Supervisor(es)' 
EndIf
                                                                            
oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , 2360 } , oBrush )
oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , 2360 )
oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , _cSubTitulo , oFont12b ) // IIf( _nOpc == 1 , 'Coordenador(es)' , 'Vendedor(es)' ) 

nlinha += ( nSaltoLinha )
nLinInBox := nlinha

Return

/*
===============================================================================================================================
Programa----------: ROMS019PRT
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime dados do relatório
Parametros--------: _lOpc : .T. = Imprime número da página / .F. = Não imprime número da página
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019PRT( cCliente , cCnpj , cRede , cUf , cMunicip , cTel , cUltCompra , cNomeFan, _nLimCred, _cDtPriCom )

oPrint:Say( nlinha + nAjustAltu , nColInic + 0015 , SubStr( cCliente , 1 , 42 )	, oFont10 )    
oPrint:Say( nlinha + nAjustAltu , nColInic + 0800 , SubStr( cNomeFan , 1 , 39 )	, oFont10 ) // 0800
oPrint:Say( nlinha + nAjustAltu , nColInic + 1220 , IIf( Len( AllTrim(cCnpj) ) <= 11 , Transform( PadL(cCnpj,11) , "@R 999.999.999-99" ) , Transform( AllTrim( cCnpj ) , "@R! NN.NNN.NNN/NNNN-99" ) ) , oFont10 ) // 1520
oPrint:Say( nlinha + nAjustAltu , nColInic + 1550 , SubStr( cRede , 1 , 25 )	, oFont10 )  // 1850
oPrint:Say( nlinha + nAjustAltu , nColInic + 2060 , cUf							, oFont10 )     // 2360
oPrint:Say( nlinha + nAjustAltu , nColInic + 2120 , SubStr( cMunicip , 1 , 19 )	, oFont10 )  // 2420
oPrint:Say( nlinha + nAjustAltu , nColInic + 2495 , cTel						, oFont10 )  // 2795
oPrint:Say( nlinha + nAjustAltu , nColInic + 2730 , DToC( SToD( cUltCompra ) )	, oFont10 )  // 3130 // 2830

oPrint:Say( nlinha + nAjustAltu , nColInic + 2915 , Transform( _nLimCred, "@E 999,999,999.99" )	, oFont10 ) // 3465
oPrint:Say( nlinha + nAjustAltu , nColInic + 3165 , DToC( SToD( _cDtPriCom) )	, oFont10 ) // 3800

Return

/*
===============================================================================================================================
Programa----------: ROMS019PAG
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime dados do relatório
Parametros--------: _lImpBox - Define se deve imprimir o box de separação
------------------: _lSetLin - Define se atualiza a posição da linha do Box
------------------: _nTipo   - Define o Tipo de Box a ser impresso
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019PAG( _lImpBox , _lSetLin , _nTipo )

//====================================================================================================
// Verifica Quebra de pagina
//====================================================================================================
If nLinha > nqbrPagina
	
	If _lImpBox
	
		If _nTipo == 1
			ROMS019BOX()
		Else
			oPrint:Box(nLinInBox,nColInic,nLinha,nColFinal)
		EndIf
		
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina.
	oPrint:StartPage()	// Inicia uma nova Pagina
	
	nPagina++
	
	ROMS019CAB( .T. )	// Chama impressão do cabecalho
	
	nlinha += nSaltoLinha
	
	If _nTipo == 1
		ROMS019CDD()		// Imprime cabeçalho dos dados
	EndIf
	
	If _lSetLin
		nLinInBox := nlinha
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS019BOX
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime box para divisão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019BOX()       

oPrint:Line( nLinInBox , nColInic + 0795 , nLinha , nColInic + 0795 ) //NOME FANTASIA
oPrint:Line( nLinInBox , nColInic + 1215 , nLinha , nColInic + 1215 ) //CLIENTE  // 1515
oPrint:Line( nLinInBox , nColInic + 1545 , nLinha , nColInic + 1545 ) //CNPJ     // 1845
oPrint:Line( nLinInBox , nColInic + 2045 , nLinha , nColInic + 2045 ) //UF       // 2345
oPrint:Line( nLinInBox , nColInic + 2115 , nLinha , nColInic + 2115 ) //MUNICIPIO // 2415 
oPrint:Line( nLinInBox , nColInic + 2475 , nLinha , nColInic + 2475 ) //TELEFONE   // 2775
oPrint:Line( nLinInBox , nColInic + 2725 , nLinha , nColInic + 2725 ) //REDE       // 3075

oPrint:Line( nLinInBox , nColInic + 2910 , nLinha , nColInic + 2910 ) //Limite de Credito
oPrint:Line( nLinInBox , nColInic + 3120 , nLinha , nColInic + 3120 ) //Primeira Compra

oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa----------: ROMS019PRC
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime o conteúdo do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019PRC()

Local _cAlias		:= GetNextAlias()
Local _aCoord		:= {}
Local _aSuper		:= {}
Local _aVend		:= {}
Local _cQuery		:= ""
Local _nConAtu		:= 0
Local _lEntrCo		:= .F.
Local _lEntrSu      := .F.
Local _cCooAtu		:= ''
Local _cSupAtu		:= ''
Local _cEndGer, _cBairGer, _cCEPGer, _cCidGer, _cEstGer, _cEmailGer, _cDDDGEr, _cTelGer
Local _cEndCoord, _cBairCoord, _cCEPCoord, _cCidCoord, _cEstCoord, _cEmailCoord, _cDDDCoord, _cTelCoord
Local _cEndSup, _cBairSup, _cCEPSup, _cCidSup, _cEstSup, _cEmailSup, _cDDDSup, _cTelSup
Local _cEndVend, _cBairVend, _cCEPVend, _cCidVend, _cEstVend, _cEmailVend, _cDDDVend, _cTelVend
Local _aCabec := {}
Local _aDadosRel :={}
Local _cTitulo := ""
Local _lImprCab := .F.

_cQuery := " SELECT DISTINCT "
_cQuery += "     SA3.A3_COD   ,"
_cQuery += "     SA3.A3_NOME  ,"

If MV_PAR06 == 4 // Listagem por clientes / para emissão das notas fiscais.
   //---------------------------------------------
   //----------- QUERY TOTAL DE NOTAS EMITIDAS PARA O CLIENTE
   _cQuery += "     (SELECT COUNT(*) FROM " + RETSQLNAME("SF2") + " SF2 " + "WHERE SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA AND SF2.d_e_l_e_t_ = ' ' AND SF2.F2_TIPO = 'N') NFS_CLIENTE , "

   //----------- QUERY TOTAL DE NOTAS EMITIDAS PARA A REDE
   _cQuery += "     (  Case WHEN SA1.A1_GRPVEN  = '999999' THEN 0 "
   _cQuery += "             Else (SELECT COUNT(*) FROM " + RETSQLNAME("SF2")+ " SF2, " + RETSQLNAME("SA10") +" REDE "
   _cQuery += "                   where SF2.d_e_l_e_t_ = ' ' AND SF2.F2_TIPO = 'N'  AND REDE.A1_COD = SF2.F2_CLIENTE AND REDE.A1_LOJA = SF2.F2_LOJA  AND "
   _cQuery += "             REDE.A1_GRPVEN = SA1.A1_GRPVEN  )   
   _cQuery += "                END ) NFS_REDE, "
   //---------------------------------------------
   //---------- Para a condição de pagamento.
   _cQuery += "     A1_COND  AS CONDPAGTO, "
   //---------------------------------------------
   //---------- Para ultima nota fiscal emitida
   _cQuery += "     (SELECT MAX(F2_EMISSAO) FROM " + RETSQLNAME("SF2") + " SF2 " + "WHERE SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA AND SF2.d_e_l_e_t_ = ' ' AND SF2.F2_TIPO = 'N') DT_ULTIMANF , "
EndIf 


If MV_PAR06 <> 1
   _cQuery += "     SA3.A3_SUPER ,"
   _cQuery += "     ( SELECT X1.A3_NOME FROM "+ RetSqlName('SA3') +" X1 WHERE X1.A3_COD = SA3.A3_SUPER AND X1.D_E_L_E_T_ = ' ' ) DESCCOORD ,"
EndIf

If MV_PAR06 <> 1 .And. MV_PAR06 <> 2
   _cQuery += "     SA3.A3_I_SUPE ,"
   _cQuery += "     ( SELECT X3.A3_NOME FROM "+ RetSqlName('SA3') +" X3 WHERE X3.A3_COD = SA3.A3_I_SUPE AND X3.D_E_L_E_T_ = ' ' ) DESCSUP ,"
EndIf

_cQuery += "     SA3.A3_GEREN ,"
_cQuery += "     ( SELECT X2.A3_NOME FROM "+ RetSqlName('SA3') +" X2 WHERE X2.A3_COD = SA3.A3_GEREN AND X2.D_E_L_E_T_ = ' ' ) DESCGER "

If MV_PAR06 == 4
   _cQuery += " ,   SA1.A1_COD     ,"
   _cQuery += "     SA1.A1_LOJA    ,"
   _cQuery += "     SA1.A1_NOME    ,"
   _cQuery += "     SA1.A1_NREDUZ  ,"
   _cQuery += "     SA1.A1_CGC     ,"
   _cQuery += "     SA1.A1_GRPVEN  ,"
   _cQuery += "     ACY.ACY_DESCRI ,"
   _cQuery += "     A1_END         ,"
   _cQuery += "     A1_BAIRRO      ,"
   _cQuery += "     A1_CEP         ,"
   _cQuery += "     A1_I_EMAIL     ,"
   _cQuery += "     SA1.A1_EST     ,"
   _cQuery += "     SA1.A1_MUN     ,"
   _cQuery += "     SA1.A1_DDD     ,"
   _cQuery += "     SA1.A1_TEL     ,"
   _cQuery += "     SA1.A1_ULTCOM  ,"
   _cQuery += "     SA1.A1_LC      ,"
   _cQuery += "     SA1.A1_PRICOM  ,"
   _cQuery += "     SA1.A1_I_GRCLI ,"
   _cQuery += "     SA1.A1_I_SUBCO  "


EndIf

_cQuery += " FROM "+ RetSqlName("SA3") + " SA3 "

If MV_PAR06 == 4
   _cQuery += " JOIN "+ RetSqlName("SA1") + " SA1 ON SA3.A3_COD    = SA1.A1_VEND OR SA3.A3_COD = SA1.A1_I_VEND2 "
   _cQuery += " JOIN "+ RetSqlName("ACY") + " ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN "
EndIf

_cQuery += " WHERE "
_cQuery += "     SA3.D_E_L_E_T_ = ' ' "

If MV_PAR06 == 1
   _cQuery += " AND SA3.A3_I_TIPV  = 'C' "
ElseIf MV_PAR06 == 2
   _cQuery += " AND SA3.A3_I_TIPV  = 'S' "   
Else
   _cQuery += " AND SA3.A3_I_TIPV  = 'V' "
EndIf

If MV_PAR06 == 4
   _cQuery += " AND SA1.D_E_L_E_T_ = ' ' "
   _cQuery += " AND ACY.D_E_L_E_T_ = ' ' "
EndIf

//====================================================================================================
// Verifica o Filtro por Gerente
//====================================================================================================
If !Empty(MV_PAR01)
   _cQuery += " AND SA3.A3_GEREN   IN "+ FormatIn( MV_PAR01 , ";" )
EndIf

//====================================================================================================
// Verifica o Filtro por Coordenador
//====================================================================================================
If !Empty(MV_PAR02)
   _cQuery += " AND SA3.A3_SUPER   IN "+ FormatIn( MV_PAR02 , ";" )
EndIf


//====================================================================================================
// Verifica o Filtro por Supervisor
//====================================================================================================
If !Empty(MV_PAR03) .And. (MV_PAR06 == 4 .Or. MV_PAR06 == 3)
   _cQuery += " AND SA3.A3_I_SUPE   IN "+ FormatIn( MV_PAR03 , ";" )
EndIf


//====================================================================================================
// Verifica o Filtro por Vendedor
//====================================================================================================
If !Empty(MV_PAR04) 
   _cQuery += " AND SA3.A3_COD     IN "+ FormatIn( MV_PAR04 , ";" )
EndIf

//====================================================================================================
// Verifica o Filtro por Rede
//====================================================================================================
If MV_PAR06 == 4 .And. !Empty(MV_PAR05)
   _cQuery += " AND SA1.A1_GRPVEN   IN "+ FormatIn( MV_PAR05 , ";" )
EndIf

//====================================================================================================
// Verifica o Filtro por Bloqueio de Vendedor
//====================================================================================================
If MV_PAR07 == 2
   _cQuery += " AND SA3.A3_MSBLQL <> '1' "
EndIf

//====================================================================================================
// Verifica o Filtro por Bloqueio de Cliente
//====================================================================================================
If MV_PAR06 == 4 .And. MV_PAR08 == 2
  _cQuery += " AND SA1.A1_MSBLQL <> '1' "
EndIf

_cQuery += " ORDER BY "

If MV_PAR06 == 4
   _cQuery += " SA3.A3_GEREN , SA3.A3_SUPER, SA3.A3_I_SUPE , SA3.A3_COD , SA1.A1_COD , SA1.A1_LOJA "
ElseIf MV_PAR06 == 3
   _cQuery += " SA3.A3_GEREN , SA3.A3_SUPER , SA3.A3_I_SUPE , SA3.A3_COD "
ElseIf MV_PAR06 == 2
   _cQuery += " SA3.A3_GEREN , SA3.A3_SUPER , SA3.A3_COD "
Else
   _cQuery += " SA3.A3_GEREN , SA3.A3_COD "
EndIf

//====================================================================================================
// Inicializa e contabiliza o numero de registros encontrados pela Query
//====================================================================================================
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
COUNT TO nCountRec

If  nCountRec > 1000
   If !U_ITMsg("Serão lidos "+AllTrim(Str(nCountRec))+" Registros. Continua?","Hr Ini: "+cTimeInicial+" Hr final "+TIME(),,3,2,2)
      Return .F.
   EndIf
EndIf
_cTot:=AllTrim(Str(nCountRec))
_nTam:=Len(_cTot)+1

ProcRegua( nCountRec )

If nCountRec > 0
   //====================================================================================================
   // Gera Relatório Impresso
   //====================================================================================================
   If MV_PAR09 == 2  // Relatório impresso
   
	  oPrint:StartPage()		// Inicia uma nova Pagina
	  ROMS019CAB( .T. )		// Chama cabecalho
	  nlinha += nSaltoLinha	// Salta Linha
	
	  DBSelectArea(_cAlias)
	  (_cAlias)->( DBGoTop() )
	  While (_cAlias)->( !Eof() )
		
		 _nConAtu++
		 IncProc( "Processando... ["+ StrZero( _nConAtu , _nTam ) +"] de ["+ _cTot +"]") 
		
		 //====================================================================================================
		 // Relatorio de Gerentes x Coordenadores x Supervisores x Vendedores x Clientes
		 //====================================================================================================
		 If MV_PAR06 == 4 
		
		    _lEntrCo := .F. // Variavel utilizada para veririficar se entrou no coordenador no registro corrente
		
			If aScan( _aCoord , {|x| AllTrim(x[1]) == AllTrim((_cAlias)->A3_SUPER) } ) == 0 // Verifica se é a primeira ocorrencia do supervisor
			    
			    If  Len(_aCoord) > 0 .And. !_lEntrCo // Verifica se nao é o primeiro registro relacionado a um vendedor
			    
					ROMS019BOX()
					
					nlinha += nSaltoLinha
					
					oPrint:EndPage()		// Finaliza a Pagina.
					oPrint:StartPage()		// Inicia uma nova Pagina.
					
					nPagina++
					
					ROMS019CAB( .T. )
					
					nlinha += nSaltoLinha	// Salta Linha.
					
				EndIf	
			                           
			    ROMS019PAG( .T. , .F. , 1 )								 // Verifica a necessidade de quebra de página
			    ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	 // Imprime novo cabecalho de Gerente
			    ROMS019CSC( (_cAlias)->A3_SUPER , (_cAlias)->DESCCOORD ) // Imprime novo cabecalho de Coordenador
			    ROMS019CSS( (_cAlias)->A3_I_SUPE, (_cAlias)->DESCSUP)    // Imprime novo cabeçalho de Supervisor.
			    aAdd( _aCoord , { (_cAlias)->A3_SUPER } )				 // Alimenta o vetor para controle do processamento
			    aAdd( _aSuper , { (_cAlias)->A3_I_SUPE } )				 // Alimenta o vetor para controle do processamento
			    _lEntrCo := .T.											 // Ajusta variável de controle
			
			EndIf
					
			If aScan( _aSuper , {|x| AllTrim(x[1]) == AllTrim((_cAlias)->A3_I_SUPE) } ) == 0 // Verifica se é a primeira ocorrencia do supervisor
			    
			    If  Len(_aSuper) > 0 .And. !_lEntrSu // Verifica se nao é o primeiro registro relacionado a um vendedor
			    
					ROMS019BOX()
					
					nlinha += nSaltoLinha
					
					oPrint:EndPage()		// Finaliza a Pagina.
					oPrint:StartPage()		// Inicia uma nova Pagina.
					
					nPagina++
					
					ROMS019CAB( .T. )
					
					nlinha += nSaltoLinha	// Salta Linha.
					
				EndIf	
			                           
			    ROMS019PAG( .T. , .F. , 1 )								 // Verifica a necessidade de quebra de página
			    ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	 // Imprime novo cabecalho de Gerente
			    ROMS019CSC( (_cAlias)->A3_SUPER , (_cAlias)->DESCCOORD ) // Imprime novo cabecalho de Coordenador
			    ROMS019CSS( (_cAlias)->A3_I_SUPE, (_cAlias)->DESCSUP)    // Imprime novo cabeçalho de Supervisor.
			    aAdd( _aCoord , { (_cAlias)->A3_SUPER } )				 // Alimenta o vetor para controle do processamento
			    aAdd( _aSuper , { (_cAlias)->A3_I_SUPE } )				 // Alimenta o vetor para controle do processamento
			    _lEntrSu := .T.											 // Ajusta variável de controle
			
			EndIf
			
			If aScan( _aVend , {|x| AllTrim(x[1]) == AllTrim((_cAlias)->A3_COD) } ) == 0 // Verifica se eh a primeira ocorrencia do vendedor
			    
			    If Len(_aVend) > 0 .And. !_lEntrCo .And. nLinInBox <> nlinha // Verifica se não é o primeiro registro relacionado a um vendedor
			    
					ROMS019BOX()
					nlinha += nSaltoLinha
					
				EndIf
				
				ROMS019PAG( .F. , .F. , 1 )								// Verifica a necessidade de quebra de pagina
			    ROMS019CVN( (_cAlias)->A3_COD , (_cAlias)->A3_NOME )	// Imprime cabecalho do Vendedor
			    aAdd( _aVend , { (_cAlias)->A3_COD } )		  			// Alimenta o vetor para futuras comparacoes
				ROMS019CDD()											// Imprime cabecalho dos dados dos Clientes
				nLinInBox := nlinha
			
			EndIf
			
			//====================================================================================================
			// Imprime os dados dos Clientes do Vendedor corrente
			//====================================================================================================
			ROMS019PRT(	(_cAlias)->A1_COD +'/'+ (_cAlias)->A1_LOJA +'-'+ AllTrim( (_cAlias)->A1_NOME )	,; // Código/Loja-Nome
						(_cAlias)->A1_CGC																,; // CPF/CNPJ
						AllTrim( (_cAlias)->ACY_DESCRI )												,; // Grupo de Clientes
						(_cAlias)->A1_EST																,; // Estado (UF)
						AllTrim( (_cAlias)->A1_MUN )													,; // Município
						"("+ (_cAlias)->A1_DDD +") "+ AllTrim( (_cAlias)->A1_TEL )						,; // DDD + Telefone
						(_cAlias)->A1_ULTCOM															,; // Data da última compra
						AllTrim( (_cAlias)->A1_NREDUZ )											,; //		 ) // Nome Fantasia
                  (_cAlias)->A1_LC,;                                                // Limite de Crédito
                  (_cAlias)->A1_PRICOM )                                            // Dt.Primeira Compra
			
			nlinha += nSaltoLinha
		    oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
			
			If _nConAtu <> nCountRec
				ROMS019PAG( .T. , .T. , 1 ) // Verifica a necessidade de quebra de pagina
			Else
				ROMS019BOX()
			EndIf 
		
		//====================================================================================================
		// Relatorio de Gerentes x Coordenadores x Supervisores x Vendedores
		//====================================================================================================
		ElseIf MV_PAR06 == 3 
			
			If Empty(_cCooAtu) .And. Empty(_cSupAtu)
			   If (_lImprCab .And. (nlinha + nSaltoLinha) > nqbrPagina) .Or. !_lImprCab .Or. (nlinha + nSaltoLinha) > nqbrPagina
			      			      
			      nlinha += nSaltoLinha
				
			      ROMS019PAG( .T. , .F. , 2 )						  		// Verifica a necessidade de quebra de página
			      ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	// Imprime o cabecalho de Gerente
			      ROMS019CSC( (_cAlias)->A3_SUPER , (_cAlias)->DESCCOORD )  // Imprime o cabecalho do Coordenador
			      ROMS019CSS( (_cAlias)->A3_I_SUPE, (_cAlias)->DESCSUP)     // Imprime novo cabeçalho de Supervisor.
			      _cCooAtu := AllTrim((_cAlias)->A3_SUPER)				    // Alimenta o vetor para controle do processamento // AllTrim((_cAlias)->A3_SUPER)
			      _cSupAtu := AllTrim((_cAlias)->A3_I_SUPE)				    // Alimenta o vetor para controle do processamento // AllTrim((_cAlias)->A3_SUPER)
			      ROMS019CLV(2)											    // Imprime Cabecalho - Vendedores
			      _lImprCab := .T.
			   EndIf
			ElseIf _cCooAtu <> AllTrim((_cAlias)->A3_SUPER) .Or. _cSupAtu <> AllTrim((_cAlias)->A3_I_SUPE)  // Verifica se mudou o coordenador  // _cCooAtu <> AllTrim((_cAlias)->A3_SUPER)
			    
			   If !Empty( _cCooAtu ) .Or. _lImprCab // Verifica se nao é o primeiro registro relacionado a um coordenador
				  oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )
			   EndIf
				
			   nlinha += nSaltoLinha
				
			   ROMS019PAG( .T. , .F. , 2 )						  		 // Verifica a necessidade de quebra de página
			   ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	 // Imprime o cabecalho de Gerente
			   ROMS019CSC( (_cAlias)->A3_SUPER , (_cAlias)->DESCCOORD )  // Imprime o cabecalho do Coordenador
			   ROMS019CSS( (_cAlias)->A3_I_SUPE, (_cAlias)->DESCSUP)     // Imprime novo cabeçalho de Supervisor.
		       _cCooAtu := AllTrim((_cAlias)->A3_SUPER)				    // Alimenta o vetor para controle do processamento // AllTrim((_cAlias)->A3_SUPER)
		       _cSupAtu := AllTrim((_cAlias)->A3_I_SUPE)				    // Alimenta o vetor para controle do processamento // AllTrim((_cAlias)->A3_SUPER)
			   ROMS019CLV(2)							
			    				 // Imprime Cabecalho - Vendedores
			ElseIf (nlinha + nSaltoLinha) > nqbrPagina
			   
			   nlinha += nSaltoLinha
				
			   ROMS019PAG( .T. , .F. , 2 )						  		 // Verifica a necessidade de quebra de página
			   ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	 // Imprime o cabecalho de Gerente
			   ROMS019CSC( (_cAlias)->A3_SUPER , (_cAlias)->DESCCOORD )  // Imprime o cabecalho do Coordenador
			   ROMS019CSS( (_cAlias)->A3_I_SUPE, (_cAlias)->DESCSUP)     // Imprime novo cabeçalho de Supervisor.
		       _cCooAtu := AllTrim((_cAlias)->A3_SUPER)				    // Alimenta o vetor para controle do processamento // AllTrim((_cAlias)->A3_SUPER)
		       _cSupAtu := AllTrim((_cAlias)->A3_I_SUPE)				    // Alimenta o vetor para controle do processamento // AllTrim((_cAlias)->A3_SUPER)
			   ROMS019CLV(2)											 // Imprime Cabecalho - Vendedores
			EndIf
			
			//====================================================================================================
			// Imprime dados dos vendedores
			//====================================================================================================
			oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , SubStr( (_cAlias)->A3_COD + '-' + (_cAlias)->A3_NOME , 1 , 120 ) , oFont12 )
			
			nlinha += nSaltoLinha  
			oPrint:Line( nLinha , nColInic , nLinha , nColFinal )    
		
		//====================================================================================================
		// Relatorio de Gerentes x Coordenadores x Supervisores 
		//====================================================================================================
		ElseIf MV_PAR06 == 2
			
			If _cCooAtu <> AllTrim((_cAlias)->A3_SUPER) // Verifica se mudou o coordenador
			    
				If  !Empty( _cCooAtu ) // Verifica se nao é o primeiro registro relacionado a um coordenador
					oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )
				EndIf
				
				nlinha += nSaltoLinha
				
			    ROMS019PAG( .T. , .F. , 2 )						  		 // Verifica a necessidade de quebra de página
			    ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	 // Imprime o cabecalho de Gerente
			    ROMS019CSC( (_cAlias)->A3_SUPER , (_cAlias)->DESCCOORD ) // Imprime o cabecalho do Coordenador
			    _cCooAtu := AllTrim((_cAlias)->A3_SUPER)				 // Alimenta o vetor para controle do processamento
			    ROMS019CLV(3)											 // Imprime Cabecalho - Vendedores  // ROMS019CLV(2)
			
			EndIf
			
			//====================================================================================================
			// Imprime dados dos vendedores
			//====================================================================================================
			oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , SubStr( (_cAlias)->A3_COD + '-' + (_cAlias)->A3_NOME , 1 , 120 ) , oFont12 )
			
			nlinha += nSaltoLinha  
			oPrint:Line( nLinha , nColInic , nLinha , nColFinal )    
			
			ROMS019PAG( .T. , .T. , 2 ) // Verifica a necessidade de quebra de pagina
		
		//====================================================================================================
		// Relatorio de Gerentes x Coordenadores
		//====================================================================================================
		ElseIf MV_PAR06 == 1
			
			If aScan( _aCoord , {|x| AllTrim(x[1]) == AllTrim((_cAlias)->A3_GEREN) } ) == 0 // Verifica se é a primeira ocorrencia do gerente
			    
				If  Len( _aCoord ) > 0 // Verifica se nao é o primeiro registro relacionado a um coordenador
				
					oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )
					nlinha += nSaltoLinha
					
				EndIf
				
			    ROMS019PAG( .T. , .F. , 2 )						  		// Verifica a necessidade de quebra de página
			    ROMS019CSG( (_cAlias)->A3_GEREN , (_cAlias)->DESCGER )	// Imprime o cabecalho de Gerente
			    aAdd( _aCoord , { (_cAlias)->A3_GEREN } )				// Alimenta o vetor para controle do processamento
			    ROMS019CLV(1)											// Imprime Cabecalho - Coordenadores
			
			EndIf
			
			//====================================================================================================
			// Imprime dados dos vendedores
			//====================================================================================================
			oPrint:Say( nlinha + nAjustAltu , nColInic + 15 , SubStr( (_cAlias)->A3_COD + '-' + (_cAlias)->A3_NOME , 1 , 120 ) , oFont12 )
			
			nlinha += nSaltoLinha  
			oPrint:Line( nLinha , nColInic , nLinha , nColFinal )    
			
			ROMS019PAG( .T. , .T. , 2 ) // Verifica a necessidade de quebra de pagina
		
		 EndIf
	
	     (_cAlias)->( DBSkip() )
	  EndDo
	
	  oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal ) // Finaliza o ultimo box
	
   //====================================================================================================
   // Gera Relatório em Excel
   //====================================================================================================
   Else  // Relatório em Excel
      //=======================================================
      // Define o Array de Títulos/cabeçalho do relatório.
      //=======================================================
      If MV_PAR06 == 1
         //=========================
	     // Gerente X Coordenador
	     //=========================
	     _cTitulo := "Relatório de Gerente X Coordenador"
	     _aCabec := {"Cod.Gerente",;  // Grava dados do Gerente
                     "Nome Gerente",; 
                     "Endereço Ger.",;
                     "Bairro Ger.",;
                     "CEP Ger.",;
                     "Cidade Ger.",;
                     "Estado Ger.",;    
                     "DDD Ger.",;
                     "Telefone Ger.",;
                     "E-Mail Ger.",;
                     "Cod.Coordenador",; // Grava dados do Coordenador
                     "Nome Coordenador",; 
                     "Endereço Coord.",;    
                     "Bairro Coord.",;
                     "CEP Coord.",;    
                     "Cidade Coord.",;
                     "Estado Coord.",;
                     "DDD Coord.",;
                     "Telefone Coord.",;
                     "E-Mail Coord."}
	     
      ElseIf MV_PAR06 == 2
         //===============================================  
	     // Gerente X Coordenador X Supervisor
	     //===============================================  
	     _cTitulo := "Relatório de Gerente X Coordenador X Supervisor"
	     _aCabec := {"Cod.Gerente",;  // Grava dados do Gerente
                     "Nome Gerente",; 
                     "Endereço Ger.",;
                     "Bairro Ger.",;
                     "CEP Ger.",;
                     "Cidade Ger.",;
                     "Estado Ger.",;    
                     "DDD Ger.",;
                     "Telefone Ger.",;
                     "E-Mail Ger.",;
                     "Cod.Coordenador",; // Grava dados do Coordenador
                     "Nome Coordenador",; 
                     "Endereço Coord.",;    
                     "Bairro Coord.",;
                     "CEP Coord.",;    
                     "Cidade Coord.",;
                     "Estado Coord.",;
                     "DDD Coord.",;
                     "Telefone Coord.",;
                     "E-Mail Coord.",;
                     "Cod.Supervisor",; // Grava dados do Supervisor.
                     "Nome Supervisor",;
                     "Endereço Sup.",;
                     "Bairro Sup.",;
                     "CEP Sup.",;
                     "Cidade Sup.",;   
                     "Estado Sup.",;
                     "DDD Sup.",;
                     "Telefone Sup.",;
                     "E-Mail Sup."}
	     
      ElseIf MV_PAR06 == 3
         //=======================================================
         // Gerente X Coordenador X Supervisor X Vendedor
         //=======================================================
         _cTitulo := "Relatório de Gerente X Coordenador X Supervisor X Vendedor"
         _aCabec := {"Cod.Gerente",;  // Grava dados do Gerente
                     "Nome Gerente",; 
                     "Endereço Ger.",;
                     "Bairro Ger.",;
                     "CEP Ger.",;
                     "Cidade Ger.",;
                     "Estado Ger.",;    
                     "DDD Ger.",;
                     "Telefone Ger.",;
                     "E-Mail Ger.",;
                     "Cod.Coordenador",; // Grava dados do Coordenador
                     "Nome Coordenador",; 
                     "Endereço Coord.",;    
                     "Bairro Coord.",;
                     "CEP Coord.",;    
                     "Cidade Coord.",;
                     "Estado Coord.",;
                     "DDD Coord.",;
                     "Telefone Coord.",;
                     "E-Mail Coord.",;
                     "Cod.Supervisor",; // Grava dados do Supervisor.
                     "Nome Supervisor",;
                     "Endereço Sup.",;
                     "Bairro Sup.",;
                     "CEP Sup.",;
                     "Cidade Sup.",;   
                     "Estado Sup.",;
                     "DDD Sup.",;
                     "Telefone Sup.",;
                     "E-Mail Sup.",;
                     "Cod.Vendedor",; // Grava dados do Vendedor
                     "Nome Vendedor",;
                     "Endereço Vend.",;
                     "Bairro Vend.",;
                     "CEP Vend.",;
                     "Cidade Vend.",;
                     "Estado Vend.",;
                     "DDD Vend.",;
                     "Telefone Vend.",;
                     "E-Mail Vend."}
      Else//MV_PAR06 = 4
         //===================================================================== 
	     // Gerente X Coordenador X Supervisor X Vendedor X Clientes
	     //===================================================================== 
	     _cTitulo := "Relatório de Gerente X Coordenador X Supervisor X Vendedor X Clientes"
	     _aCabec := {"Cod.Gerente",;  // Grava dados do Gerente
                     "Nome Gerente",; 
                     "Endereço Ger.",;
                     "Bairro Ger.",;
                     "CEP Ger.",;
                     "Cidade Ger.",;
                     "Estado Ger.",;    
                     "DDD Ger.",;
                     "Telefone Ger.",;
                     "E-Mail Ger.",;
                     "Cod.Coordenador",; // Grava dados do Coordenador
                     "Nome Coordenador",; 
                     "Endereço Coord.",;    
                     "Bairro Coord.",;
                     "CEP Coord.",;    
                     "Cidade Coord.",;
                     "Estado Coord.",;
                     "DDD Coord.",;
                     "Telefone Coord.",;
                     "E-Mail Coord.",;
                     "Cod.Supervisor",; // Grava dados do Supervisor.
                     "Nome Supervisor",;
                     "Endereço Sup.",;
                     "Bairro Sup.",;
                     "CEP Sup.",;
                     "Cidade Sup.",;   
                     "Estado Sup.",;
                     "DDD Sup.",;
                     "Telefone Sup.",;
                     "E-Mail Sup.",;
                     "Cod.Vendedor",; // Grava dados do Vendedor
                     "Nome Vendedor",;
                     "Endereço Vend.",;
                     "Bairro Vend.",;
                     "CEP Vend.",;
                     "Cidade Vend.",;
                     "Estado Vend.",;
                     "DDD Vend.",;
                     "Telefone Vend.",;
                     "E-Mail Vend.",;
                     "Cód.Cliente",; // Grava dados dos Clientes 
                     "Loja Cliente",;
                     "Nome Cliente",;
                     "CPF / CNPJ Clien.",;
                     "Grupo de Clientes",;
                     "Endereço Clien.",;
                     "Bairro Clien.",;  
                     "CEP Clien.",;
                     "E-mail Clien.",;
                     "Estado (UF) Clien.",;
                     "Município Clien.",; 
                     "DDD Clien.",;
                     "Telefone Clien.",;
                     "Dt.Última Nf Emitida.",; // Dt.Última Compra 
                     "Nome Fantasia Clien.",;
                     "Limite Cred",;
                     "Prim. Compra",;
                     "Total Nfs do Cliente.",;
                     "Total Nfs da Rede",;
                     "Condição Pagamento",;
                     "Descrição Condição"}

         aAdd(_aCabec,"Cód. Segmento"   )        
         aAdd(_aCabec,"Segmento"        )  
         aAdd(_aCabec,"Cód. Subsegmento")        
         aAdd(_aCabec,"Subsegmento"     )  
                     
      EndIf   
      
      SA3->(DBSetOrder(1)) // A3_FILIAL+A3_COD
      
      DBSelectArea(_cAlias)
	  (_cAlias)->( DBGoTop() )
	  
	  While (_cAlias)->( !Eof() )
		
		 _nConAtu++
		 IncProc( "Processando... ["+ StrZero( _nConAtu , 6 ) +"] de ["+ StrZero( nCountRec , 6 ) +"]") 
		
		 //====================================================================================================
		 // Relatorio de Gerentes x Coordenadores x Supervisores x Vendedores x Clientes
		 //====================================================================================================
		 If MV_PAR06 == 4 
          //=================================================================
          // Buscando descrição da condição de pagamento
          //=================================================================
          _cDescCond :=  Posicione("SE4",1,xFilial("SE4")+(_cAlias)->CONDPAGTO,"E4_DESCRI") 

		    //=================================================================
		    // Busca dados complementares do Gerente.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_GEREN))
	        _cEndGer   := SA3->A3_END    
            _cBairGer  := SA3->A3_BAIRRO 
            _cCEPGer   := SA3->A3_CEP    
            _cCidGer   := SA3->A3_MUN    
            _cEstGer   := SA3->A3_EST    
            _cDDDGEr   := SA3->A3_DDDTEL 
            _cTelGer   := SA3->A3_TEL
            _cEmailGer := SA3->A3_EMAIL
           	       
	        //=================================================================
		    // Busca dados complementares do Coordenador.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_SUPER))
	        _cEndCoord   := SA3->A3_END    
            _cBairCoord  := SA3->A3_BAIRRO 
            _cCEPCoord   := SA3->A3_CEP    
            _cCidCoord   := SA3->A3_MUN    
            _cEstCoord   := SA3->A3_EST    
            _cDDDCoord   := SA3->A3_DDDTEL 
            _cTelCoord   := SA3->A3_TEL
            _cEmailCoord := SA3->A3_EMAIL	       
           
	        //=================================================================
		    // Busca dados complementares do Supervisor
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_I_SUPE))
	        _cEndSup   := SA3->A3_END    
            _cBairSup  := SA3->A3_BAIRRO 
            _cCEPSup   := SA3->A3_CEP    
            _cCidSup   := SA3->A3_MUN    
            _cEstSup   := SA3->A3_EST    
            _cDDDSup   := SA3->A3_DDDTEL 
            _cTelSup   := SA3->A3_TEL 
            _cEmailSup := SA3->A3_EMAIL
	       
	        //=================================================================
		    // Busca dados complementares do Vendedor
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_COD))
	        _cEndVend   := SA3->A3_END    
            _cBairVend  := SA3->A3_BAIRRO 
            _cCEPVend   := SA3->A3_CEP    
            _cCidVend   := SA3->A3_MUN    
            _cEstVend   := SA3->A3_EST    
            _cDDDVend   := SA3->A3_DDDTEL 
            _cTelVend   := SA3->A3_TEL
            _cEmailVend := SA3->A3_EMAIL		

		    //=======================================================================================================
		    // Monta Array de Dados do Relatorio de Gerentes x Coordenadores x Supervisores x Vendedores x Clientes
		    //=======================================================================================================
		    aAdd(_aDadosRel,{(_cAlias)->A3_GEREN,;                 // Cod.Gerente <<< ===== >>> // Grava dados do Gerente
		                     (_cAlias)->DESCGER,;                  // Nome Gerente 
		                     _cEndGer,;                            // Endereço Ger.
                           _cBairGer,;                           // Bairro Ger.
                           _cCEPGer,;                            // CEP Ger.
                           _cCidGer,;                            // Cidade Ger.
                           _cEstGer,;                            // Estado Ger.    
                           _cDDDGEr,;                            // DDD Ger.
                           _cTelGer,;                            // Telefone Ger.
                           _cEmailGer,;                          // E-Mail Ger.
		                     (_cAlias)->A3_SUPER,;                 // Cod.Coordenador <<< ===== >>>  // Grava dados do Coordenador
		                     (_cAlias)->DESCCOORD,;                // Nome Coordenador 
		                     _cEndCoord,;                          // Endereço Coord.    
                           _cBairCoord,;                         // Bairro Coord.
                           _cCEPCoord,;                          // CEP Coord.    
                           _cCidCoord,;                          // Cidade Coord.
                           _cEstCoord,;                          // Estado Coord.
                           _cDDDCoord,;                          // DDD Coord.
                           _cTelCoord,;                          // Telefone Coord.
                           _cEmailCoord,;                        // E-Mail Coord.
		                     (_cAlias)->A3_I_SUPE,;                // Cod.Supervisor <<< ===== >>>  // Grava dados do Supervisor.
		                     (_cAlias)->DESCSUP,;                  // Nome Supervisor 
		                     _cEndSup,;                            // Endereço Sup.
                           _cBairSup,;                           // Bairro Sup.
                           _cCEPSup,;                            // CEP Sup.
                           _cCidSup,;                            // Cidade Sup.   
                           _cEstSup,;                            // Estado Sup.
                           _cDDDSup,;                            // DDD Sup.
                           _cTelSup,;                            // Telefone Sup.
                           _cEmailSup,;                          // E-Mail Sup.
	                        (_cAlias)->A3_COD,;                   // Cod.Vendedor <<< ===== >>> // Grava dados do Vendedor
	                        (_cAlias)->A3_NOME,; 	              // Nome Vendedor
	                        _cEndVend,;                           // Endereço Vend.
                           _cBairVend,;                          // Bairro Vend.
                           _cCEPVend,;                           // CEP Vend.
                           _cCidVend,;                           // Cidade Vend.
                           _cEstVend,;                           // Estado Vend.
                           _cDDDVend,;                           // DDD Vend.
                           _cTelVend,;                           // Telefone Vend.
                           _cEmailVend,;                         // E-Mail Vend.
		                     (_cAlias)->A1_COD,;                   // Cód.Cliente  <<< ===== >>> // Grava dados dos Clientes 
		                     (_cAlias)->A1_LOJA,;                  // Loja Cliente
		                     (_cAlias)->A1_NOME,;  	              // Nome Cliente
                           (_cAlias)->A1_CGC,;	                 // CPF / CNPJ Clien.
		                     (_cAlias)->ACY_DESCRI,;               // Grupo de Clientes
		                     (_cAlias)->A1_END,;                   // Endereço Clien.
                           (_cAlias)->A1_BAIRRO,;                // Bairro Clien.  
                           (_cAlias)->A1_CEP,;                   // CEP Clien.
                           (_cAlias)->A1_I_EMAIL,;               // E-mail Clien.
                           (_cAlias)->A1_EST,;	                 // Estado (UF) Clien.
		                     (_cAlias)->A1_MUN,;                   // Município Clien. 
		                     (_cAlias)->A1_DDD,;                   // DDD Clien.
		                     (_cAlias)->A1_TEL,;                   // Telefone Clien.
		                     DToC( SToD((_cAlias)->DT_ULTIMANF)),; // A1_ULTCOM,;	// Dt.Última Compra Clien.
		                     (_cAlias)->A1_NREDUZ,;                // Nome Fantasia Clien.
		                     (_cAlias)->A1_LC,;                    // Limite de Credito
                           DToC( SToD((_cAlias)->A1_PRICOM)),;   // Primeira Compra
                           (_cAlias)->NFS_CLIENTE,;              // Notas fiscais emitidas p/cliente
                           (_cAlias)->NFS_REDE,;                 // Notas fiscais emitidas para rede do cliente
                           (_cAlias)->CONDPAGTO,;                // Condição de Pagamento
                           _cDescCond,;                          // Descrição da Condição de Pagamento.
                           (_cAlias)->A1_I_GRCLI,;                     //"Cód. Segmento"   
                           Posicione("ZZ6",1,xFilial("ZZ6") + (_cAlias)->A1_I_GRCLI, "ZZ6_DESCRO"),;//"Segmento"        
                           (_cAlias)->A1_I_SUBCO,;                     //"Cód. Subsegmento"
                           Posicione("ZS6",1,xFilial()+(_cAlias)->A1_I_GRCLI+(_cAlias)->A1_I_SUBCO,"ZS6_DESCRI");//"Subsegmento"     
                           })           

		 //======================================================================
		 // Relatorio de Gerentes x Coordenadores x Supervisores x Vendedores
		 //======================================================================
		 ElseIf MV_PAR06 == 3 
		    //=================================================================
		    // Busca dados complementares do Gerente.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_GEREN))
	        _cEndGer   := SA3->A3_END    
            _cBairGer  := SA3->A3_BAIRRO 
            _cCEPGer   := SA3->A3_CEP    
            _cCidGer   := SA3->A3_MUN    
            _cEstGer   := SA3->A3_EST    
            _cDDDGEr   := SA3->A3_DDDTEL 
            _cTelGer   := SA3->A3_TEL
            _cEmailGer := SA3->A3_EMAIL
           	       
	        //=================================================================
		    // Busca dados complementares do Coordenador.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_SUPER))
	        _cEndCoord   := SA3->A3_END    
            _cBairCoord  := SA3->A3_BAIRRO 
            _cCEPCoord   := SA3->A3_CEP    
            _cCidCoord   := SA3->A3_MUN    
            _cEstCoord   := SA3->A3_EST    
            _cDDDCoord   := SA3->A3_DDDTEL 
            _cTelCoord   := SA3->A3_TEL
            _cEmailCoord := SA3->A3_EMAIL	       
           
	        //=================================================================
		    // Busca dados complementares do Supervisor
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_I_SUPE))
	        _cEndSup   := SA3->A3_END    
            _cBairSup  := SA3->A3_BAIRRO 
            _cCEPSup   := SA3->A3_CEP    
            _cCidSup   := SA3->A3_MUN    
            _cEstSup   := SA3->A3_EST    
            _cDDDSup   := SA3->A3_DDDTEL 
            _cTelSup   := SA3->A3_TEL 
            _cEmailSup := SA3->A3_EMAIL
	        
	        //=================================================================
		    // Busca dados complementares do Vendedor
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_COD))
	        _cEndVend   := SA3->A3_END    
            _cBairVend  := SA3->A3_BAIRRO 
            _cCEPVend   := SA3->A3_CEP    
            _cCidVend   := SA3->A3_MUN    
            _cEstVend   := SA3->A3_EST    
            _cDDDVend   := SA3->A3_DDDTEL 
            _cTelVend   := SA3->A3_TEL
            _cEmailVend := SA3->A3_EMAIL		

            //============================================================================================
		    // Monta Array de Dados do Relatorio de Gerentes x Coordenadores x Supervisores x Vendedores
		    //============================================================================================
            aAdd(_aDadosRel,{(_cAlias)->A3_GEREN,;  // Cod.Gerente <<< ===== >>> // Grava dados do Gerente
		                     (_cAlias)->DESCGER,;   // Nome Gerente 
		                     _cEndGer,; // Endereço Ger.
                             _cBairGer,; // Bairro Ger.
                             _cCEPGer,;  // CEP Ger.
                             _cCidGer,;  // Cidade Ger.
                             _cEstGer,;  // Estado Ger.    
                             _cDDDGEr,;  // DDD Ger.
                             _cTelGer,;  // Telefone Ger.
                             _cEmailGer,; // E-Mail Ger.
		                     (_cAlias)->A3_SUPER,;  // Cod.Coordenador <<< ===== >>>  // Grava dados do Coordenador
		                     (_cAlias)->DESCCOORD,; // Nome Coordenador 
		                     _cEndCoord,;   // Endereço Coord.    
                             _cBairCoord,;  // Bairro Coord.
                             _cCEPCoord,;   // CEP Coord.    
                             _cCidCoord,;   // Cidade Coord.
                             _cEstCoord,;   // Estado Coord.
                             _cDDDCoord,;   // DDD Coord.
                             _cTelCoord,;   // Telefone Coord.
                             _cEmailCoord,; // E-Mail Coord.
		                     (_cAlias)->A3_I_SUPE,; // Cod.Supervisor <<< ===== >>>  // Grava dados do Supervisor.
		                     (_cAlias)->DESCSUP,;   // Nome Supervisor 
		                     _cEndSup,;   // Endereço Sup.
                             _cBairSup,;  // Bairro Sup.
                             _cCEPSup,;   // CEP Sup.
                             _cCidSup,;   // Cidade Sup.   
                             _cEstSup,;   // Estado Sup.
                             _cDDDSup,;   // DDD Sup.
                             _cTelSup,;   // Telefone Sup.
                             _cEmailSup,; // E-Mail Sup.
	                         (_cAlias)->A3_COD,;    // Cod.Vendedor <<< ===== >>> // Grava dados do Vendedor
	                         (_cAlias)->A3_NOME,; 	// Nome Vendedor
	                         _cEndVend,;   // Endereço Vend.
                             _cBairVend,;  // Bairro Vend.
                             _cCEPVend,;   // CEP Vend.
                             _cCidVend,;   // Cidade Vend.
                             _cEstVend,;   // Estado Vend.
                             _cDDDVend,;   // DDD Vend.
                             _cTelVend,;   // Telefone Vend.
                             _cEmailVend}) // E-Mail Vend.
                                       
		 //====================================================================================================
		 // Relatorio de Gerentes x Coordenadores x Supervisores 
		 //====================================================================================================
		 ElseIf MV_PAR06 == 2
            //=================================================================
		    // Busca dados complementares do Gerente.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_GEREN))
	        _cEndGer   := SA3->A3_END    
            _cBairGer  := SA3->A3_BAIRRO 
            _cCEPGer   := SA3->A3_CEP    
            _cCidGer   := SA3->A3_MUN    
            _cEstGer   := SA3->A3_EST    
            _cDDDGEr   := SA3->A3_DDDTEL 
            _cTelGer   := SA3->A3_TEL
            _cEmailGer := SA3->A3_EMAIL
           	       
	        //=================================================================
		    // Busca dados complementares do Coordenador.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_SUPER))
	        _cEndCoord   := SA3->A3_END    
            _cBairCoord  := SA3->A3_BAIRRO 
            _cCEPCoord   := SA3->A3_CEP    
            _cCidCoord   := SA3->A3_MUN    
            _cEstCoord   := SA3->A3_EST    
            _cDDDCoord   := SA3->A3_DDDTEL 
            _cTelCoord   := SA3->A3_TEL
            _cEmailCoord := SA3->A3_EMAIL	       
           
	        //=================================================================
		    // Busca dados complementares do Supervisor
		    //=================================================================
	        //SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_I_SUPE))
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_COD))
	        _cEndSup   := SA3->A3_END              
            _cBairSup  := SA3->A3_BAIRRO 
            _cCEPSup   := SA3->A3_CEP    
            _cCidSup   := SA3->A3_MUN    
            _cEstSup   := SA3->A3_EST    
            _cDDDSup   := SA3->A3_DDDTEL 
            _cTelSup   := SA3->A3_TEL 
            _cEmailSup := SA3->A3_EMAIL
	       
	        //==============================================================================
		    // Monta Array de Dados do Relatorio de Gerentes x Coordenadores x Supervisores 
		    //==============================================================================
            aAdd(_aDadosRel,{(_cAlias)->A3_GEREN,;  // Cod.Gerente <<< ===== >>> // Grava dados do Gerente
		                     (_cAlias)->DESCGER,;   // Nome Gerente 
		                     _cEndGer,; // Endereço Ger.
                             _cBairGer,; // Bairro Ger.
                             _cCEPGer,;  // CEP Ger.
                             _cCidGer,;  // Cidade Ger.
                             _cEstGer,;  // Estado Ger.    
                             _cDDDGEr,;  // DDD Ger.
                             _cTelGer,;  // Telefone Ger.
                             _cEmailGer,; // E-Mail Ger.
		                     (_cAlias)->A3_SUPER,;  // Cod.Coordenador <<< ===== >>>  // Grava dados do Coordenador
		                     (_cAlias)->DESCCOORD,; // Nome Coordenador 
		                     _cEndCoord,;   // Endereço Coord.    
                             _cBairCoord,;  // Bairro Coord.
                             _cCEPCoord,;   // CEP Coord.    
                             _cCidCoord,;   // Cidade Coord.
                             _cEstCoord,;   // Estado Coord.
                             _cDDDCoord,;   // DDD Coord.
                             _cTelCoord,;   // Telefone Coord.
                             _cEmailCoord,; // E-Mail Coord.
		                     (_cAlias)->A3_COD,; // A3_I_SUPE,; // Cod.Supervisor <<< ===== >>>  // Grava dados do Supervisor.
		                     (_cAlias)->A3_NOME,; //DESCSUP,;   // Nome Supervisor 
		                     _cEndSup,;   // Endereço Sup.
                             _cBairSup,;  // Bairro Sup.
                             _cCEPSup,;   // CEP Sup.
                             _cCidSup,;   // Cidade Sup.   
                             _cEstSup,;   // Estado Sup.
                             _cDDDSup,;   // DDD Sup.
                             _cTelSup,;   // Telefone Sup.
                             _cEmailSup}) // E-Mail Sup.       
		   
		 //====================================================================================================
		 // Relatorio de Gerentes x Coordenadores
		 //====================================================================================================
		 ElseIf MV_PAR06 == 1
            //=================================================================
		    // Busca dados complementares do Gerente.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_GEREN))
	        _cEndGer   := SA3->A3_END    
            _cBairGer  := SA3->A3_BAIRRO 
            _cCEPGer   := SA3->A3_CEP    
            _cCidGer   := SA3->A3_MUN    
            _cEstGer   := SA3->A3_EST    
            _cDDDGEr   := SA3->A3_DDDTEL 
            _cTelGer   := SA3->A3_TEL
            _cEmailGer := SA3->A3_EMAIL
            	       
	        //=================================================================
		    // Busca dados complementares do Coordenador.
		    //=================================================================
	        SA3->(DBSeek(xFilial("SA3")+(_cAlias)->A3_COD)) // (_cAlias)->A3_SUPER))
	        _cEndCoord   := SA3->A3_END    
            _cBairCoord  := SA3->A3_BAIRRO 
            _cCEPCoord   := SA3->A3_CEP    
            _cCidCoord   := SA3->A3_MUN    
            _cEstCoord   := SA3->A3_EST    
            _cDDDCoord   := SA3->A3_DDDTEL 
            _cTelCoord   := SA3->A3_TEL
            _cEmailCoord := SA3->A3_EMAIL	       
           
            //==============================================================================
		    // Monta Array de Dados do Relatorio de Gerentes x Coordenadores x Supervisores 
		    //==============================================================================
            aAdd(_aDadosRel,{(_cAlias)->A3_GEREN,;  // Cod.Gerente <<< ===== >>> // Grava dados do Gerente
		                     (_cAlias)->DESCGER,;   // Nome Gerente 
		                     _cEndGer,; // Endereço Ger.
                             _cBairGer,; // Bairro Ger.
                             _cCEPGer,;  // CEP Ger.
                             _cCidGer,;  // Cidade Ger.
                             _cEstGer,;  // Estado Ger.    
                             _cDDDGEr,;  // DDD Ger.
                             _cTelGer,;  // Telefone Ger.
                             _cEmailGer,; // E-Mail Ger.
		                     (_cAlias)->A3_COD,; // (_cAlias)->A3_SUPER,;  // Cod.Coordenador <<< ===== >>>  // Grava dados do Coordenador
		                     (_cAlias)->A3_NOME,; // (_cAlias)->DESCCOORD,; // Nome Coordenador 
		                     _cEndCoord,;   // Endereço Coord.    
                             _cBairCoord,;  // Bairro Coord.
                             _cCEPCoord,;   // CEP Coord.    
                             _cCidCoord,;   // Cidade Coord.
                             _cEstCoord,;   // Estado Coord.
                             _cDDDCoord,;   // DDD Coord.
                             _cTelCoord,;   // Telefone Coord.
                             _cEmailCoord}) // E-Mail Coord.	
           
		 EndIf
	
	     (_cAlias)->( DBSkip() )
	  EndDo
    
      If Empty(_aDadosRel)
         U_ITMsg("Com base nas condições de filtros informados, não foram encontrados dados para emissão do relatório.","Atenção", ,1) 
      Else
         _cTitulo:=_cTitulo+" (ROMS019)"
         U_ITListBox(_cTitulo , _aCabec , _aDadosRel , .T. , 1 , "Exportação excel/arquivo")
      EndIf  
      
   EndIf  
EndIf

(_cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: ROMS019PAR
Autor-------------: Fabiano Dias
Data da Criacao---: 15/06/2010
Descrição---------: Imprime a página de parâmetros do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS019PAR()

Local _crelat := ""

If MV_PAR06 == 1
	_CRELAT := "Ger-Coo"
EndIf
If MV_PAR06 == 2
	_CRELAT := "Ger-Coo-Sup"
EndIf
If MV_PAR06 == 3
	_CRELAT := "Ger-Coo-Sup-Ven"
EndIf
If MV_PAR06 == 4
	_CRELAT := "Ge-Co-Su-Ve-Cli"
EndIf

nLinha += 60
oPrint:Say (nLinha,nColInic + 10,"Pergunta 01 : Gerente ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , MV_PAR01 , oFont14Prb )
nLinha += 60
	
oPrint:Say (nLinha,nColInic + 10,"Pergunta 02 : Coordenador ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , MV_PAR02 , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 03 : Supervisor ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , MV_PAR03 , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 04 : Vendedor ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , MV_PAR04 , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 05 : Rede ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , MV_PAR05 , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 06 : Relatório ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , _crelat , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 07 : Coord/Vend Bloqueado ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , IIf(MV_PAR07==1,"Sim","Não") , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 08 : Cliente Bloqueado ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , IIf(MV_PAR08==1,"Sim",IIf(MV_PAR08==2,"Não","Ambos")) , oFont14Prb )
nLinha += 60

oPrint:Say (nLinha,nColInic + 10,"Pergunta 09 : Gera Relat. Excel ?",oFont14Prb)    
oPrint:Say( nLinha , 1200 , IIf(MV_PAR08==1,"Sim",IIf(MV_PAR08==2,"Não","Ambos")) , oFont14Prb )
nLinha += 60

nLinha += 60
oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
oPrint:EndPage()

Return
