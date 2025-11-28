/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 21/08/2023 | Chamado 43822. Ajustes na impressão e Layout de datas 
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes e Defines da Rotina. 
//====================================================================================================
#Include "TOTVS.ch"

#Define TITULO "Consulta Vendedores - Log de Alterações"

/*
===============================================================================================================================
Programa----------: COMS006
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/12/2021
===============================================================================================================================
Descrição---------: Consulta Histórico de Alterações do Cadastro de Vendedores- Chamado 35404
===============================================================================================================================
Parametros--------: _cModo = "P" = Vendedor Posicionado.
                             "C" = Digitar Código.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function COMS006(_cModo)

Local cCodVen		:= Space( TamSX3("A3_COD")[01] )
Local aParRet		:= { cCodVen }
Local aParamBox 	:= {}

Private cCadastro	:= "Consulta: Log de Alterações - Vendedores"

Default _cModo := "C"//Digitar Código.

//================================================================================
//| Verifica se a rotina foi chamada do menu ou do Cadastro de Vendedores        |
//================================================================================
//If FunName() <> "COMS006"
If _cModo == "P"// "P" = Vendedor Posicionado.
	
   COMS006HIS( SA3->( A3_COD ) )
	
Else//Digitar Código.

	aAdd( aParamBox	, { 1 , "Selecione o Vendedor " , cCodVen , "@!" , "" , "SA3" , "" , 50 , .T. } )
	
	If ParamBox( aParamBox , "Informar os dados para a Consulta:" , @aParRet , {|| COMS006VLD( SA3->A3_COD ) } ,, .T. , , , , , .F. , .F. )
		
		//If aParRet[01] != SA3->A3_COD
		    Z07->(DBSetOrder(1)) // Z07_FILIAL+Z07_ALIAS+Z07_ORDEM+Z07_CHAVE+Z07_OPCAO+Z07_CAMPO+Z07_CODUSU+Z07_DATA+Z07_HORA

			DBSelectArea("SA3")
			SA3->(DBSetOrder(1))
			If !SA3->( DBSeek( xFilial("SA3") + aParRet[01] ) )
               If ! Z07->( DBSeek( xFilial("Z07") + "SA3 1" + xFilial("SA3") + aParRet[01] ) )
				  //Aviso( 'Atenção!' , "O código de - Vendedor informado não foi encontrado." , TITULO , 0 )
				  U_ITMsg("O código de - Vendedor informado não foi encontrado.","Atenção",,1)
				  Return
			   EndIf 
			EndIf
			
		//EndIf
		
		COMS006HIS( aParRet[01] )
	
	EndIf

EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: COMS006VLD
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/12/2021
===============================================================================================================================
Descrição---------: Validação do Vendedor selecionado/informado
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS006VLD( cChvVen )

Local lRet := .F.

//================================================================================
//| Verifica se o Vendedor informado/selecionado existe no Cadastro (SA3)         |
//================================================================================
DBSelectArea("SA3")
SA3->( DBSetOrder(1) )
If SA3->( MSSeek( xFilial("SA3") + cChvVen ) )
	lRet := .T.
Else
	MessageBox( "O Fornecedor informado ["+ cChvVen +"] não é válido." , TITULO , 0 )
	lRet := .F.
EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: COMS006HIS
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/12/2021
===============================================================================================================================
Descrição---------: Monta a tela detalhada do Histórico de Alterações do Cadastro do Vendedor
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS006HIS( cCodVen )

Local oDlg			:= Nil
Local oLbxTOP		:= Nil
Local oLbxDET		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bMontaTOP		:= { || Processa({|lEnd| COMS006LOG( @oLbxTOP , cCodVen ) }) }
Local bMontaDET		:= { || COMS006DET( @oLbxDET , oLbxTOP:aArray[oLbxTOP:nAt][04] , oLbxTOP:aArray[oLbxTOP:nAt][01] ) }

Local oBar			:= Nil
Local aBtn 	    	:= Array(02)
Local oBold			:= Nil
Local oScrPanel		:= Nil

Local aCabLbxTOP	:= { "Loja", "Campo" , "Última Alt." , "Registro (Recno SA3)" } // 04

Local _cChavPesq    := Space(8)

Local aCabLbxDET	:= { "Data"				,; // 01
                         "Hora"				,; // 02
                         "Usuário"			,; // 03
                         "Nome Usr."		,; // 04
                         "Cont. Orig."		,; // 05
                         "Cont. Alt."		 } // 06

Local _cCodVend := Space(6)
Local _cNomeVend := Space(40)

Private	nDvPosAnt	:= 0
Private	cCadastro	:= "["+ cCodVen +"] - " + TITULO

Default cCodVen		:= ""

If Empty(cCodVen)
	Return
EndIf

//================================================================================
//| Posiciona no Cadastro do Vendedor                                           |
//================================================================================
DBSelectArea("SA3")
SA3->(DBSetOrder(1))
If !SA3->( DBSeek( xFilial("SA3") + cCodVen ) )
   _cCodVend  := cCodVen
   _cNomeVend := "[VENDEDOR/REPRESENTANTE EXCLUIDO.]"
   If ! Z07->( DBSeek( xFilial("Z07") + "SA3 1" + xFilial("SA3") + cCodVen ) )
	  MessageBox( "O vendedor ["+ cCodVen +"] não foi encontrado." , TITULO , 0 )	
	  Return
   EndIf
   _nRegSA3   := 0
Else 
   _cCodVend  := SA3->A3_COD
   _cNomeVend := SA3->A3_NOME   
   _nRegSA3   := SA3->(RECNO())
EndIf

_cChavPesq := xFilial("SA3") + cCodVen 

//================================================================================
//| Verifica se existe histórico de alterações                                   |
//================================================================================
DBSelectArea("Z07")
Z07->( DBSetOrder(1) )

//If !Z07->( DBSeek( xFilial("Z07") + "SA3 1" + SA3->( A3_FILIAL + A3_COD ) ) )

If !Z07->( DBSeek( xFilial("Z07") + "SA3 1" + _cChavPesq ) )
	MessageBox( "O vendedor ["+ cCodVen +"] não possui histórico de alterações." , TITULO , 0 )
	Return
EndIf
Private _aColXML :={}//SÓ ZERA AQUI 
Private _aColCapa:={}//SÓ ZERA AQUI 

aAdd( aObjects, { 100 , 025 , .T. , .F. , .T. } )
aAdd( aObjects, { 100 , 070 , .T. , .F. } )
aAdd( aObjects, { 100 , 100 , .T. , .T. } )

aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	aPosObj[01][01] += 12
	aPosObj[02][01] += 10
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	
	//================================================================================
	//| Imprime o código e o nome do vendedor                                        |
	//================================================================================
	@ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED
	
	@ 004 , 004 Say "Código:" 		SIZE 025,07 OF oScrPanel PIXEL
	@ 012 , 004 Say _cCodVend    	SIZE 060,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
    //@ 012 , 004 Say SA3->A3_COD  	SIZE 060,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE

	@ 004 , 030 Say "Nome:" 		SIZE 025,07 OF oScrPanel PIXEL
	@ 012 , 030 Say _cNomeVend   	SIZE 165,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	//@ 012 , 030 Say SA3->A3_NOME 	SIZE 165,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	_cTitAux:=cCadastro+" do "+_cCodVend+"-"+_cNomeVend

	//================================================================================
	//| Monta o resumo das alterações do cadastro                                    |
	//================================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Campos Alterados" COLOR CLR_HBLUE OF oDlg PIXEL
	
	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxTOP Fields	;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
	
	oLbxTOP:AHeaders	:= aClone(aCabLbxTOP)
	oLbxTOP:bChange		:= { || Eval(bMontaDET) }
	
	Eval(bMontaTOP)
	
	//================================================================================
	//| Monta os detalhes das alterações do cadastro                                 |
	//================================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Histórico dos Campos" COLOR CLR_HBLUE OF oDlg PIXEL
	
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxDET Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
					
	oLbxDET:AHeaders := aClone(aCabLbxDET)
	
	Eval(bMontaDET)
	
	//================================================================================
	//| Monta a barra de botões da tela                                              |
	//================================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg

	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION FWMsgRun( ,{|| COMS6XMLX(_cTitAux)  },"H.I. : "+TIME()+" - Aguarde...","Gerando Excel (.XLSX)..." );//DlgToExcel({{"ARRAY","",oLbxDET:AHeaders,oLbxDET:aArray}});
	       TOOLTIP "Exportação para Excel (.XLSX)"
	
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "FINAL"	OF oBar GROUP ACTION oDlg:End() TOOLTIP "Sair da Tela..."
	
	aBtn[02]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: COMS006LOG
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/12/2021
===============================================================================================================================
Descrição---------: Monta estrutura do Log de Alterações do Vendedor
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS006LOG( oLbxAux , cCodVen )

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _nTotReg	:= 0
Local _nCont	:= 0
Local _aLbxAux  := {}

//================================================================================
//| Consulta para buscar o resumo das alterações do cadastro                     |
//================================================================================
_cQuery := " SELECT "
_cQuery += " 	Z07.Z07_CAMPO 		AS CAMPO,	"
_cQuery += " 	MAX( Z07.Z07_DATA )	AS DT_ULT,	"
_cQuery += "	SA3.R_E_C_N_O_		AS REGSA3	"
_cQuery += " FROM "+ RetSqlName("SA3") +" SA3	"
_cQuery += " INNER JOIN "+ RetSqlName("Z07") +" Z07 "
_cQuery += " ON "
_cQuery += " 		SA3.A3_FILIAL || SA3.A3_COD = Z07.Z07_CHAVE "
_cQuery += " WHERE "
_cQuery += "     	Z07.D_E_L_E_T_  = ' ' "
_cQuery += " AND	Z07.Z07_ALIAS	= 'SA3' "
_cQuery += " AND	SA3.A3_COD      = '"+ cCodVen +"' "
_cQuery += " GROUP BY Z07.Z07_CAMPO, SA3.R_E_C_N_O_ "
_cQuery += " ORDER BY Z07.Z07_CAMPO "

_cQuery	:= ChangeQuery(_cQuery)
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )

DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop())

(_cAlias)->( DBEval( { || _nTotReg++ } ) )

ProcRegua(_nTotReg)

(_cAlias)->( DBGoTop() )
_nRegSA3:=(_cAlias)->REGSA3
//================================================================================
//| Grava os dados do Resumo                                                     |
//================================================================================
While (_cAlias)->(!Eof())

    _nCont++
    IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )

	aAdd( _aLbxAux , {	(_cAlias)->CAMPO							   		,; // 01
						Posicione("SX3",2,(_cAlias)->CAMPO,"X3_DESCRIC")	,; // 02
                       	SToD((_cAlias)->DT_ULT)								,; // 03
                       	(_cAlias)->REGSA3					   				}) // 04


    (_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

_aColCapa:=ACLONE( _aLbxAux )
//================================================================================
//| Monta o objeto do ListBox                                                    |
//================================================================================
If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
						_aLbxAux[oLbxAux:nAt][02]	,; // 02
						_aLbxAux[oLbxAux:nAt][03]	,; // 03
						_aLbxAux[oLbxAux:nAt][04]	}} // 04
	
	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: COMS006DET
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/12/2021
===============================================================================================================================
Descrição---------: Monta estrutura de Detalhes do Log de Alterações do Campo
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS006DET( oLbxAux , nRegSA3 , cCampo )

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _aLbxAux	:= {} , C

//================================================================================
//| Consulta para buscar os detalhes das alterações dos campos                   |
//================================================================================
_cQuery := " SELECT "
_cQuery += " 	Z07.Z07_DATA	AS DT_ALT	, "
_cQuery += " 	Z07.Z07_HORA	AS HORA		, "
_cQuery += " 	Z07.Z07_CODUSU	AS CODUSU	, "
_cQuery += " 	Z07.Z07_CONORG	AS CONT_ORG	, "
_cQuery += " 	Z07.Z07_CONALT	AS CONT_ALT	, "
_cQuery += " 	Z07.Z07_CAMPO                 "
_cQuery += " FROM "+ RetSqlName("SA3") +" SA3 "
_cQuery += " INNER JOIN "+ RetSqlName("Z07") +" Z07 "
_cQuery += " ON "
_cQuery += " 	SA3.A3_FILIAL || SA3.A3_COD = Z07.Z07_CHAVE "
_cQuery += " WHERE "
_cQuery += " Z07.D_E_L_E_T_  = ' ' "
_cQuery += " AND	Z07.Z07_ALIAS	= 'SA3' "
_cQuery += " AND	SA3.R_E_C_N_O_	= '"+ CValToChar(nRegSA3) +"' "
If !Empty(cCampo)
   _cQuery += " AND	Z07.Z07_CAMPO	= '"+ cCampo +"' "
   _cQuery += " ORDER BY Z07.Z07_DATA , Z07.Z07_HORA , Z07.Z07_CODUSU , Z07.Z07_CONORG "
Else
   _cQuery += " ORDER BY Z07.Z07_CAMPO, Z07.Z07_DATA , Z07.Z07_HORA , Z07.Z07_CODUSU , Z07.Z07_CONORG "
EndIf

_cQuery	:= ChangeQuery(_cQuery)

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )

DBSelectArea(_cAlias)

(_cAlias)->(DBGoTop())                                                                                   

//================================================================================
//| Grava o resultado dos detalhes das alterações dos campos                     |
//================================================================================
While (_cAlias)->(!Eof())

   If !Empty(cCampo)
   
      aAdd( _aLbxAux , {		SToD((_cAlias)->DT_ALT)	  ,; // 01
                            		 (_cAlias)->HORA	  ,; // 02
                            		 (_cAlias)->CODUSU	  ,; // 03
      AllTrim( Capital( UsrFullName((_cAlias)->CODUSU) ) ),; // 04
   						 AllTrim((_cAlias)->CONT_ORG)     ,; // 05
   						 AllTrim((_cAlias)->CONT_ALT)     }) // 06
   Else
     
     _aCpos:={}
	 If (_nPos:=aScan(_aColCapa,{ |C| AllTrim(C[1]) == AllTrim((_cAlias)->Z07_CAMPO) }) ) > 0 
        aAdd( _aCpos , _aColCapa[_nPos,01]) // 01
        aAdd( _aCpos , _aColCapa[_nPos,02]) // 02
        aAdd( _aCpos , _aColCapa[_nPos,03]) // 03
        aAdd( _aCpos , _aColCapa[_nPos,04]) // 04
      Else
        aAdd( _aCpos , " " ) // 01
        aAdd( _aCpos , " " ) // 02
        aAdd( _aCpos , " " ) // 03
        aAdd( _aCpos , " " ) // 04
      EndIf

      aAdd( _aCpos , SToD((_cAlias)->DT_ALT)                              ) // 01
      aAdd( _aCpos , (_cAlias)->HORA		                              ) // 02
      aAdd( _aCpos , (_cAlias)->CODUSU	                                  ) // 03
      aAdd( _aCpos , AllTrim( Capital( UsrFullName((_cAlias)->CODUSU ) ) )) // 04
      aAdd( _aCpos , AllTrim((_cAlias)->CONT_ORG )	                      ) // 05
      aAdd( _aCpos , AllTrim((_cAlias)->CONT_ALT )	                      ) // 06
            
      aAdd( _aColXML , _aCpos )

   EndIf
   
   (_cAlias)->( DBSkip() )

EndDo

(_cAlias)->( DBCloseArea() )

//================================================================================
//| Monta o objeto do ListBox com os dados dos detalhes                          |
//================================================================================
If	!Empty(cCampo) .And. Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
						_aLbxAux[oLbxAux:nAt][02]	,; // 02
						_aLbxAux[oLbxAux:nAt][03]	,; // 03
						_aLbxAux[oLbxAux:nAt][04]	,; // 04
						_aLbxAux[oLbxAux:nAt][05]	,; // 05
						_aLbxAux[oLbxAux:nAt][06]	}} // 06

	oLbxAux:Refresh()

EndIf

Return


/*
===============================================================================================================================
Programa----------: COMS6XMLX
Autor-------------: Alex Wallauer
Data da Criacao---: 21/08/2023
===============================================================================================================================
Descrição---------: Gera o XMLX dos dados 
===============================================================================================================================
Parametros--------: _cTitAux
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function COMS6XMLX(_cTitAux)

_aCab:={}
// Alinhamento: 1-Left   ,2-Center,3-Right
// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
//          Titulo das Colunas    ,Alinhamento ,Formatação, Totaliza 
aAdd(_aCab,{"Loja"                ,1           ,1         ,.F.})
aAdd(_aCab,{"Campo"               ,1           ,1         ,.F.})
aAdd(_aCab,{"Última Alt."         ,2           ,4         ,.F.})
aAdd(_aCab,{"Registro (Recno SA3)",3           ,2         ,.F.,"@E 9,999,999"})
aAdd(_aCab,{"Data"		          ,2           ,4         ,.F.})      
aAdd(_aCab,{"Hora"		          ,2           ,1         ,.F.})      
aAdd(_aCab,{"Usuário"	          ,2           ,1         ,.F.})      
aAdd(_aCab,{"Nome Usr."           ,1           ,1         ,.F.})        
aAdd(_aCab,{"Cont. Orig."         ,1           ,1         ,.F.})      
aAdd(_aCab,{"Cont. Alt."          ,1           ,1         ,.F.})      

If Len(_aColXML) = 0
    COMS006DET(, _nRegSA3 , "" )
EndIf

U_ITGEREXCEL(,,_cTitAux,,_aCab,_aColXML,,,,,,,,.T.)

U_ITMsg("Geração Concluida!  ["+DToC(DATE())+"] ["+TIME()+"]")

Return .T.
