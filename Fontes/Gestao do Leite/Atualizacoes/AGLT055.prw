/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Alex Wallauer |26/12/2024| Chamado 48915. Ajustes para a integração WebService Italac x Evomilk
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.Ch"

#Define	TITULO	"Análise de Dados dos Produtores Rurais Recebidos do APP Cia do Leite"

/*
===============================================================================================================================
Programa----------: AGLT055
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Rotina de Análise dos dados dos Produtores Rurais recebidos dos app Cia do Leite.
                    Perminte a manuteção de alguns dados, atualização do cadastro de Produtores no Protheus e rejeição de 
                    dados recebidos. Chamado 38531.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055()
Local _cPerg := "AGLT055"

Begin Sequence 

   //MV_PAR01 = Filiais ?        
   //MV_PAR02 = Dt.Incial Envio ?
   //MV_PAR03 = Dt.final Envio ? 
   //MV_PAR04 = Enviado para ? 1-Cia do Leite", 2-EvoMilk, 3-SEM FILTRO
   //Dexei aqui Para criar em outros ambientes se preciso: PRODDUCAO OK
   //_aHelpPor := { 'Informa a tipo da integracao' }
   //U_ITPUTX1(_cPerg,"04","Enviado para ?"     ," "," ","mv_ch4","C",1,0,0,"C","","","","","MV_PAR04","Cia do Leite","","","","EvoMilk","","","SEM FILTRO","","","","","",".","","",_aHelpPor,_aHelpPor,_aHelpPor)

   If !Pergunte(_cPerg,.T.,"Selecione os Filtros para Manutenção/Consulta Integração Cia Leite / EvoMilk.")
      Break
   EndIf 

   cFiltroZBH:=""
   cFiltroZBI:=""
    If MV_PAR04 <> 3
       If MV_PAR04 = 2 
          cFiltroZBH:=" AND ZBH_WEBINT = 'E' "
          cFiltroZBI:=" AND ZBI_WEBINT = 'E' "
       Else
          cFiltroZBH:=" AND ZBH_WEBINT <> 'E' "
          cFiltroZBI:=" AND ZBI_WEBINT <> 'E' "
       EndIf
    EndIf

   //===========================================================================
   //| Define formato de data para exibição nas telas da rotina                |
   //===========================================================================
   SET DATE FORMAT TO "DD/MM/YYYY"

   Processa( {|| AGLT055INI() } , "Processando..." , "Iniciando o processamento..." )

End Sequence 
	
Return

/*
===============================================================================================================================
Programa----------: AGLT055INI
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT055INI()

Local _aCpos		:= AGLT055CPS()
Local _aFields		:= {}
Local _cQry		:= ""
Local _cAliasQry	:= GetNextAlias()
Local _lHaDados   := .F.

Private _oMarkBRW	:= Nil
Private cAliasAux	:= GetNextAlias()
Private _nTotReg	:= 0
Private cDtIni		:= ""
Private _aRegMrk	:= {}
Private _cAliasTrb 

Begin Sequence 

   _cQry := " SELECT "
   _cQry += " ZBG_TIPREG, "	// Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
   _cQry += " ZBG_FILIAL, "   // Filial do Produtor
   _cQry += " ZZM_DESCRI, "   // Nome da Filial do Produtor
   _cQry += " ZBG_COD, "		// Código do Produtor	
   _cQry += " ZBG_LOJA, "		// Loja Produtor
   _cQry += " ZBG_TIPO, "	   // Tipo do Fornecedor	Pertence("FJ")
   _cQry += " ZBG_CNPJ, "		// CPF/CNJP	
   _cQry += " ZBG_NOME, "	   // Razão Social
   _cQry += " ZBG_NREDUZ, "   // Nome Fantasia	
   _cQry += " ZBG_EST, "		// Estado	
   _cQry += " ZBG_MUN, "		// Municipio	
   _cQry += " ZBG_CEP, "		// CEP	
   _cQry += " ZBG_FAZEN, "		// Fazenda do Produtor
   _cQry += " ZBG_IDPROD, "	// Id.Produtor	
   _cQry += " ZBG_DATA, "		// Data Integra	
   _cQry += " ZBG_HORA, "		// Hora Intagra	
   _cQry += " ZBG_STATUS, "	// Status	
   _cQry += " ZBG.R_E_C_N_O_	AS REGZBG "
   _cQry += " FROM  "+ RetSqlName("ZBG") +" ZBG, " + RetSqlName("ZZM") +" ZZM "
   _cQry += " WHERE "
   _cQry += "     ZBG.D_E_L_E_T_  = ' ' AND ZBG_STATUS = 'P' "
      
   If ! Empty(MV_PAR01)
      _cQry += " AND ZBG_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
   EndIf 

   If ! Empty(MV_PAR02)
      _cQry += " AND ZBG_DATA >= '"+ DToS(MV_PAR02) + "' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQry += " AND ZBG_DATA <= '"+ DToS(MV_PAR03) + "' "
   EndIf

   _cQry += " AND ZBG_FILIAL = ZZM_CODIGO "
   
   _cQry += " ORDER BY ZBG_DATA, ZBG_IDPROD "

   If Select(_cAliasQry) > 0
	  (_cAliasQry)->( DBCloseArea() )
   EndIf

   ProcRegua(0)
   IncProc( "Lendo registros..." )
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , _cAliasQry , .T. , .F. )

   DBSelectArea(_cAliasQry)
   (_cAliasQry)->( DBGoTop() )
   COUNT TO _nTotReg

   If Select(cAliasAux) > 0
	  (cAliasAux)->(DBCloseArea())
   EndIf

   _otemp := FWTemporaryTable():New( cAliasAux, _aCpos )
   
   _otemp:AddIndex( "01", {"ZBG_IDPROD"} )
   _otemp:AddIndex( "02", {"ZBG_DATA"} )
   _otemp:AddIndex( "03", {"ZBG_NOME"} )

   _otemp:Create()

   DBSelectArea( cAliasAux )
   ProcRegua(_nTotReg)

   (_cAliasQry)->( DBGoTop() )
   While (_cAliasQry)->( !Eof() )
      _lHaDados := .T.
      (cAliasAux)->( DBAPPEND() )
      (cAliasAux)->ZBG_TIPREG := If((_cAliasQry)->ZBG_TIPREG=="N","NOVO PRODUTOR","ALTERAÇÃO DE PRODUTOR")     // Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
      (cAliasAux)->ZBG_FILIAL := (_cAliasQry)->ZBG_FILIAL
      (cAliasAux)->ZZM_DESCRI := (_cAliasQry)->ZZM_DESCRI
      (cAliasAux)->ZBG_COD    := (_cAliasQry)->ZBG_COD        // Código do Produtor	
      (cAliasAux)->ZBG_LOJA   := (_cAliasQry)->ZBG_LOJA       // Loja Produtor
      (cAliasAux)->ZBG_TIPO   := If((_cAliasQry)->ZBG_TIPO=="F","PESSOA FISICA","PESSOA JURIDICA")  // Tipo do Fornecedor	Pertence("FJ")
      (cAliasAux)->ZBG_CNPJ   := (_cAliasQry)->ZBG_CNPJ	     // CPF/CNJP	
      (cAliasAux)->ZBG_NOME   := (_cAliasQry)->ZBG_NOME	     // Razão Social
      (cAliasAux)->ZBG_NREDUZ := (_cAliasQry)->ZBG_NREDUZ     // Nome Fantasia	
      (cAliasAux)->ZBG_EST    := (_cAliasQry)->ZBG_EST	     // Estado	
      (cAliasAux)->ZBG_MUN    := (_cAliasQry)->ZBG_MUN	     // Municipio	
      (cAliasAux)->ZBG_CEP    := (_cAliasQry)->ZBG_CEP	     // CEP	
      (cAliasAux)->ZBG_FAZEN  := (_cAliasQry)->ZBG_FAZEN      // Fazenda do Produtor
      (cAliasAux)->ZBG_IDPROD := (_cAliasQry)->ZBG_IDPROD	  // Id.Produtor	
      (cAliasAux)->ZBG_DATA   := SToD((_cAliasQry)->ZBG_DATA) // Data Integra	
      (cAliasAux)->ZBG_HORA	:= (_cAliasQry)->ZBG_HORA       // Hora Intagra	
      (cAliasAux)->ZBG_STATUS := (_cAliasQry)->ZBG_STATUS	  // Status		P=Pendente Atualização;A=Atualizado;R=Rejeitado
      (cAliasAux)->WK_RECNO	:= (_cAliasQry)->REGZBG         // Recno da tabela ZBG
		
      (_cAliasQry)->( DBSkip() )
		
   EndDo

   If ! _lHaDados
      (cAliasAux)->( DBAPPEND() )
      (cAliasAux)->ZBG_TIPREG := "NÃO HA DADOS P/ATUALIZAR" //If((_cAliasQry)->ZBG_TIPREG=="N","NOVO PRODUTOR","ALTERAÇÃO DE PRODUTOR")     // Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
      (cAliasAux)->ZBG_COD    := "XXXXXX"                       // Código do Produtor	
      (cAliasAux)->ZBG_LOJA   := "XXXX"                         // Loja Produtor
      (cAliasAux)->ZBG_NOME   := "SEM DADOS PARA ATUALIZAÇÃO"	 // Razão Social
   EndIf 

   (_cAliasQry)->( DBCloseArea() )
   
   //===================================================================================
   // Cria tabelas de Work para consulta das integrações Produtores e Coletas de Leite.
   //===================================================================================
   U_AGLT055N()

   //===================================================================================
   // Exibe Tela Principal de Atualização de Produtores.
   //=================================================================================== 
   DBSelectArea("ZBG")

   aAdd( _aFields , { "Tipo de Registro"   , {|| (cAliasAux)->ZBG_TIPREG} , "C" , "@!"                   , 0 , 22 , 0 } )     // Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
   aAdd( _aFields , { "Filial"             , {|| (cAliasAux)->ZBG_FILIAL} , "C" , "@!"                   , 0 , 8  , 0 } )     // Filial
   aAdd( _aFields , { "Nome Filial"        , {|| (cAliasAux)->ZZM_DESCRI} , "C" , "@!"                   , 0 , 30 , 0 } )     // Nome Filial
   aAdd( _aFields , { "Código do Produtor" , {|| (cAliasAux)->ZBG_COD   } , "C" , "@!"                   , 0 , 6  , 0 } )     // Código do Produtor	
   aAdd( _aFields , { "Loja Produtor"		 , {|| (cAliasAux)->ZBG_LOJA  } , "C" , "@!"                   , 0 , 4  , 0 } )     // Loja Produtor
   aAdd( _aFields , { "Tipo do Fornecedor" , {|| (cAliasAux)->ZBG_TIPO  } , "C" , "@!"                   , 0 , 15 , 0 } )     // Tipo do Fornecedor	Pertence("FJ")
   aAdd( _aFields , { "CPF/CNJP"			    , {|| (cAliasAux)->ZBG_CNPJ  } , "C" , "@R! NN.NNN.NNN/NNNN-99", 0 , 14 , 0 } )     // CPF/CNJP	
   aAdd( _aFields , { "Razão Social"       , {|| (cAliasAux)->ZBG_NOME  } , "C" , "@!"                   , 0 , TamSX3("ZBG_NOME")[01]		, 0 } ) // Razão Social
   aAdd( _aFields , { "Nome Fantasia"	    , {|| (cAliasAux)->ZBG_NREDUZ} , "C" , "@!"                   , 0 , TamSX3("ZBG_NREDUZ")[01]		, 0 } )  // Nome Fantasia	
   aAdd( _aFields , { "Estado"			    , {|| (cAliasAux)->ZBG_EST   } , "C" , "@!"                   , 0 , 2  , 0 } ) // Estado	
   aAdd( _aFields , { "Municipio"		    , {|| (cAliasAux)->ZBG_MUN   } , "C" , "@!"                   , 0 , TamSX3("ZBG_MUN")[01]		, 0 } )    // Municipio	
   aAdd( _aFields , { "CEP"		          , {|| (cAliasAux)->ZBG_CEP   } , "C" , "@R 99999-999"         , 0 , 8  , 0 } )  // CEP	
   aAdd( _aFields , { "Fazenda do Produtor", {|| (cAliasAux)->ZBG_FAZEN } , "C" , "@!"                   , 0 , TamSX3("ZBG_FAZEN")[01]		, 0 } )  // Fazenda do Produtor
   aAdd( _aFields , { "Id.Produtor"		    , {|| (cAliasAux)->ZBG_IDPROD} , "C" , "@!"                   , 0 , TamSX3("ZBG_IDPROD")[01]		, 0 } ) // Id.Produtor	
   aAdd( _aFields , { "Data Integra"       , {|| (cAliasAux)->ZBG_DATA  } , "C" , "@D"                   , 0 , 8	, 0 } ) // Data Integra	
   aAdd( _aFields , { "Hora Intagra"       , {|| (cAliasAux)->ZBG_HORA  } , "C" , "@!"                   , 0 , 8	, 0 } )	 // Hora Intagra	
   aAdd( _aFields , { "Status"			    , {|| (cAliasAux)->ZBG_STATUS} , "C" , "@!"                   , 0 , 22	, 0 } ) // Status		P=Pendente Atualização;A=Atualizado;R=Rejeitado
   aAdd( _aFields , { "Recno da tabela ZBG", {|| (cAliasAux)->WK_RECNO  } , "C" , "999999999"            , 0 , 10	, 0 } ) // Recno da tabela ZBG

   _oMarkBRW := FWMarkBrowse():New()		   											// Inicializa o Browse

   _oMarkBRW:SetAlias( cAliasAux )			   											// Define Alias que será a Base do Browse
   _oMarkBRW:SetDescription( TITULO )                                        	// Define o titulo do browse de marcacao
   _oMarkBRW:SetFieldMark( "MARCA" )														// Define o campo que sera utilizado para a marcação
   _oMarkBRW:SetMenuDef( 'AGLT055' )														// Força a utilização do menu da rotina atual
   _oMarkBRW:SetAllMark( {|| _oMarkBRW:AllMark() } )						         // Ação do Clique no Header da Coluna de Marcação
   _oMarkBRW:SetFields( _aFields )													 		// Campos para exibição
   
   _oMarkBRW:AddLegend({|| (cAliasAux)->ZBG_STATUS == "P"}, "BR_VERMELHO", "Pendente Atualização")
   _oMarkBRW:AddLegend({|| (cAliasAux)->ZBG_STATUS == "A"}, "BR_AZUL"    , "Atualizado")
   _oMarkBRW:AddLegend({|| (cAliasAux)->ZBG_STATUS == "R"}, "BR_CINZA"   , "Rejeitado")

   _oMarkBRW:DisableConfig()

   _oMarkBRW:Activate()	// Ativacao da classe

End Sequence 

If Select(cAliasAux) > 0
   (cAliasAux)->(DBCloseArea())
EndIf

Return 

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Rotina de construção do menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina Title 'Pesquisar'                Action 'U_AGLT055S((cAliasAux)->WK_RECNO)'   OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visualizar'               Action 'U_AGLT055R((cAliasAux)->WK_RECNO)'   OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Atualizar Produtor'       Action 'U_AGLT055G((cAliasAux)->WK_RECNO)'   OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Rejeitar Dados Produtor'  Action 'U_AGLT055F((cAliasAux)->WK_RECNO)'   OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Alterar'                  Action 'U_AGLT055A((cAliasAux)->WK_RECNO)'   OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Visul.Rej.Envio Produtor' Action 'U_AGLT055V("R")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visulizar Envio Produtor' Action 'U_AGLT055V("A")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visul.Rej.Dados Coleta'   Action 'U_AGLT055Y("R")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visulizar Envio Coleta'   Action 'U_AGLT055Y("A")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Legenda'                  Action 'U_AGLT055LEG()'                      OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT055E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Visualizar dados integrado do Produtor Posicionado.
Parametros--------: Recno da tabela ZBG.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055R( nRegZBG )

Private cCadastro := "Visualizar - Cad.Aprovação Atualiza Produtores"

Begin Sequence 
   
   If Empty(nRegZBG)
      Break 
   EndIf 

   DBSelectArea("ZBG")
   ZBG->( DBGoTo(nRegZBG) )
   AxVisual( "ZBG" , nRegZBG , 2 ) 

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AGLT055A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Alterar dados integrados do Produtor Posicionado.                    
Parametros--------: Recno da tabela ZBG.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055A( nRegZBG )

Private cCadastro := "Cad.Aprovação Atualiza Produtores - Alteração"

Begin Sequence 
   
   If Empty(nRegZBG)
      Break 
   EndIf 

   DBSelectArea("ZBG")
   ZBG->( DBGoTo(nRegZBG) )

   //AxAltera( <cAlias>, <nReg>  , <nOpc>, <aAcho>, <aCpos>, <nColMens>, <cMensagem>, <cTudoOk>, <cTransact>, <cFunc>, <aButtons>, <aParam>, <aAuto>, <lVirtual>, <lMaximized>)
   AxAltera( "ZBG"   , nRegZBG , 4     ,        ,        ,           ,            ,          ,  "U_AGLT055T()")

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AGLT055CPS
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Define a criação de campos para exibição da análise
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function AGLT055CPS()

Local _aCpos := {}

Begin Sequence 

   aAdd( _aCpos , { "MARCA"		, "C" ,  2, 0 } )
   aAdd( _aCpos , { "ZBG_TIPREG"	, "C" , 22, 0 } )	// Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
   aAdd( _aCpos , { "ZBG_FILIAL"	, "C" ,  2, 0 } ) // Filial
   aAdd( _aCpos , { "ZZM_DESCRI"	, "C" , 30, 0 } ) // Nome da Filail
   aAdd( _aCpos , { "ZBG_COD"		, "C" ,  6, 0 } )	// Código do Produtor	
   aAdd( _aCpos , { "ZBG_LOJA"	, "C" ,  4, 0 } )	// Loja Produtor
   aAdd( _aCpos , { "ZBG_TIPO"	, "C" , 15, 0 } )	// Tipo do Fornecedor	Pertence("FJ") PESSOA FISICA/PESSOA JURIDICA
   aAdd( _aCpos , { "ZBG_CNPJ"	, "C" , 14,	0 } )	// CPF/CNJP	
   aAdd( _aCpos , { "ZBG_NOME"	, "C" , 40,	0 } )	// Razão Social
   aAdd( _aCpos , { "ZBG_NREDUZ"	, "C" , 20,	0 } )	// Nome Fantasia	
   aAdd( _aCpos , { "ZBG_EST"		, "C" ,  2, 0 } )	// Estado	
   aAdd( _aCpos , { "ZBG_MUN"		, "C" , 50, 0 } )	// Municipio	
   aAdd( _aCpos , { "ZBG_CEP"		, "C" ,  8, 0 } )	// CEP	
   aAdd( _aCpos , { "ZBG_FAZEN"	, "C" , 40, 0 } )	// Fazenda do Produtor
   aAdd( _aCpos , { "ZBG_IDPROD"	, "C" , 12, 0 } )	// Id.Produtor	
   aAdd( _aCpos , { "ZBG_DATA"	, "D" ,  8, 0 } )	// Data Integra	
   aAdd( _aCpos , { "ZBG_HORA"	, "C" ,  8, 0 } )	// Hora Intagra	
   aAdd( _aCpos , { "ZBG_STATUS"	, "C" ,  1, 0 } )	// Status		P=Pendente Atualização;A=Atualizado;R=Rejeitado
   aAdd( _aCpos , { "WK_RECNO"	, "N" , 10, 0 } )	// Recno da tabela ZBG

End Sequence

Return( _aCpos )

/*
===============================================================================================================================
Programa----------: AGLT055LEG()
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Função utilizada para exibir a legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055LEG()
Local _aLegenda :=	{	{"BR_VERMELHO", "Pendente Atualização"},;
		      		      {"BR_AZUL"    , "Atualizado"},;
                        {"BR_CINZA"   , "Rejeitado"}}

BrwLegenda(TITULO,"Legenda",_aLegenda)

Return

/*
===============================================================================================================================
Programa----------: AGLT055S
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Permite pesquisar um Produtor na tela.
Parametros--------: nRegZBG = Recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055S(nRegZBG)

Local _oGet1	  := Nil 
Local _oDlgP	  := Nil 
Local _cGet1	  := Space(60)
Local _nOpca	  := 0
Local _cComboBx1  := "Id.Produtor"
Local _aComboBx1  := {"Id.Produtor","Nome"}
Local _nRegAtu    := (cAliasAux)->(Recno())

Begin Sequence 
   
   If Empty(nRegZBG)
      Break    
   EndIf 
   
   DEFINE MSDIALOG _oDlgP TITLE "Pesquisar Produtor" FROM 178,181 TO 259,697 PIXEL

      @ 004,003 ComboBox	_cComboBx1	Items _aComboBx1 Size 213,010 OF _oDlgP PIXEL
	   @ 020,003 MsGet		_oGet1	Var _cGet1		Size 212,009 OF _oDlgP PIXEL COLOR CLR_BLACK Picture "@!"
	
	   DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlgP:End() ) OF _oDlgP
	   DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlgP:End() ) OF _oDlgP

   ACTIVATE MSDIALOG _oDlgP CENTERED

   If _nOpca == 1
      If AllTrim(_cComboBx1) == AllTrim(_aComboBx1[1])
         (cAliasAux)->(DBSetOrder(1)) // Ordem por ID.PRODUTOR
      Else
         (cAliasAux)->(DBSetOrder(3)) // Ordem por NOME       
      EndIf 
   
      If ! (cAliasAux)->(MsSeek(RTrim(_cGet1)))
         U_ITMsg("Registro não encontrado.","Atenção",,1)
         (cAliasAux)->(DBSetOrder(1))
         (cAliasAux)->(DBGoTo(_nRegAtu))
      Else 
         (cAliasAux)->(DBSetOrder(1))
         _oMarkBRW:Refresh()
      EndIf 
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AGLT055G
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Atualização do cadastro de Produtores Rurais.
Parametros--------: nRegZBG = recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055G(nRegZBG)

Local _cPerg := "AGLT055W"

Begin Sequence 

   MV_PAR01 := Nil 
   MV_PAR02 := Nil
   MV_PAR03 := Nil 

   If ! Pergunte(_cPerg,.T.,"Selecione os Filtros para Manutenção/Consulta Integração Cia Leite")
      Break
   EndIf 

   If ! U_ITMsg("Confirma a atualização do cadastro de Produtores para os registros selecionados?","Atenção" , , ,2, 2)
      Break 
   EndIf 
   
   Processa( {|| U_AGLT055H() } , "Processando..." , "Atualizando o Cadastro de Produtores..." )

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AGLT055H
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Atualização do cadastro de Produtores Rurais.
Parametros--------: nRegZBG = Recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055H(nRegZBG)
Local _cCodFor, _cLojaFor 
Local _lIncluir 
Local _aDadosFor := {}
Local _cNomeUser := UsrFullName(__cUserId)

Private lMSErroAuto

Begin Sequence 
   
   ProcRegua(0)

   (cAliasAux)->(DBGoTop())
   While ! (cAliasAux)->(Eof())
      
      IncProc("Atualizando Cadastro Produtor...")

      If _oMarkBRW:IsMark()
         
          ZBG->(DBGoTo((cAliasAux)->WK_RECNO))

         If (cAliasAux)->ZBG_STATUS == "R"
            U_ITMsg("Não é permitido a atualização de Registros rejeitados. Produtor: " + AllTrim(ZBG->ZBG_NOME) + "." ,"Atenção",,1)
            (cAliasAux)->(DBSkip())
            Loop 
         ElseIf (cAliasAux)->ZBG_STATUS == "A"
            U_ITMsg("Os dados do produtor: "  + AllTrim(ZBG->ZBG_NOME) + ", já foram atualizados.","Atenção",,1)
            (cAliasAux)->(DBSkip())
            Loop 
         EndIf 

         If AllTrim((cAliasAux)->ZBG_TIPREG) == "NOVO PRODUTOR"
            //========================================================================
            //_pcClasse = Devera ser passado o conteudo do campo A2_I_CLASS.
            //_pcTipo   = Devera ser passado o conteudo do campo A2_TIPO.
            //_pcCGC    = Devera ser passado o conteudo do campo A2_CGC.
            //_cCodFor := U_ACOM005( _pcClasse , _pcTipo , _pcCGC )
            _cCodFor := U_ACOM005( "P" , ZBG->ZBG_TIPO , ZBG->ZBG_CNPJ )

            // _pcCGC    = Devera ser passado o conteudo do campo A2_CGC.
            // cCodigo   = Devera ser passado o conteudo do campo A2_COD.
            // cClass    = Devera ser passado o conteudo do campo A2_I_CLASS.
            If Empty(_cCodFor)
               U_ITMsg("Não foi possivel gerar o código do fornecedor para o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
               (cAliasAux)->(DBSkip())
               Loop
            EndIf 
            _cLojaFor := U_ACOM006( ZBG->ZBG_CNPJ , _cCodFor , "P" )
            _lIncluir := .T.
                        
            aAdd( _aDadosFor , {	"A2_I_CLASS"	, "P"								               , nil } )  // Produtor 
            aAdd( _aDadosFor , {	"A2_CGC"		   , ZBG->ZBG_CNPJ	      	               , nil } )
            aAdd( _aDadosFor , {	"A2_COD"		   , _cCodFor						               , nil } )
            aAdd( _aDadosFor , {	"A2_LOJA"		, _cLojaFor					               	, nil } )
            aAdd( _aDadosFor , {	"A2_PAIS"		, '105'		 					               , nil } )
            aAdd( _aDadosFor , {	"A2_CODPAIS"	, '01058'	 					               , nil } )
            aAdd( _aDadosFor , {	"A2_TRIBFAV"	, '2'	 						                	, nil } )
            //aAdd( _aDadosFor , {	"A2_MSBLQL"	   , '2'		   				                	, nil } )
            aAdd( _aDadosFor , {	"A2_INDCP"	   , '1'		   				                	, nil } )
            aAdd( _aDadosFor , {	"A2_TIPORUR"	, 'F'		   				                	, nil } )
            aAdd( _aDadosFor , {	"A2_RECINSS"	, 'S'		   				                	, nil } )
            //========================================================================
            // Dados Cadastrais
            //========================================================================
            If ! Empty(ZBG->ZBG_NOME)
               aAdd( _aDadosFor , {	"A2_NOME"		, AllTrim(ZBG->ZBG_NOME)	  , nil } ) 
            EndIf 
            If ! Empty(ZBG->ZBG_NREDUZ)
               aAdd( _aDadosFor , {	"A2_NREDUZ"		, AllTrim(ZBG->ZBG_NREDUZ) , nil } ) 
            EndIf 
            If ! Empty(ZBG->ZBG_EST)
               aAdd( _aDadosFor , {	"A2_EST"		   , AllTrim(ZBG->ZBG_EST)	  , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_CODMUN)
               aAdd( _aDadosFor , {	"A2_COD_MUN"	, AllTrim(ZBG->ZBG_CODMUN) , nil } ) 
            EndIf 
            If ! Empty(ZBG->ZBG_MUN)
               aAdd( _aDadosFor , {	"A2_MUN"	      , AllTrim(ZBG->ZBG_MUN)    , nil } )                                                           
            EndIf 
            If ! Empty(ZBG->ZBG_CEP)
               aAdd( _aDadosFor , {	"A2_CEP"		   , AllTrim(ZBG->ZBG_CEP)	  , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_END)
               aAdd( _aDadosFor , {	"A2_END"		   , AllTrim(ZBG->ZBG_END)    , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_BAIRRO)
               aAdd( _aDadosFor , {	"A2_BAIRRO"		, AllTrim(ZBG->ZBG_BAIRRO) , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_DDD)
               aAdd( _aDadosFor , {	"A2_DDD"		   , AllTrim(ZBG->ZBG_DDD)	  , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_TEL)
               aAdd( _aDadosFor , {	"A2_TEL"		   , AllTrim(ZBG->ZBG_TEL)	  , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_EMAIL)
               aAdd( _aDadosFor , {	"A2_EMAIL"		, AllTrim(ZBG->ZBG_EMAIL)  , nil } )
            EndIf 
            If ! Empty(ZBG->ZBG_TIPO)
               aAdd( _aDadosFor , {	"A2_TIPO"		, ZBG->ZBG_TIPO  	        , nil } ) 
            EndIf 
         Else 
            _lIncluir := .F.
            aAdd( _aDadosFor , {	"A2_COD"		   , ZBG->ZBG_COD		               , nil } )
            aAdd( _aDadosFor , {	"A2_LOJA"		, ZBG->ZBG_LOJA		              	, nil } )
            
            SA2->(DBSetOrder(1))
            If ! SA2->(MsSeek(xFilial("SA2")+ZBG->ZBG_COD+ZBG->ZBG_LOJA))
               If Empty(_cCodFor)
                  U_ITMsg("Não foi possivel Localizar o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
                  (cAliasAux)->(DBSkip())
                  Loop
               EndIf 
            EndIf 

            //========================================================================
            // Dados Cadastrais
            //========================================================================
            aAdd( _aDadosFor , {	"A2_CGC"		   , SA2->A2_CGC		  , nil } )
            aAdd( _aDadosFor , {	"A2_NOME"		, SA2->A2_NOME	  , nil } ) 
            aAdd( _aDadosFor , {	"A2_NREDUZ"		, SA2->A2_NREDUZ   , nil } ) 
            aAdd( _aDadosFor , {	"A2_TIPO"		, SA2->A2_TIPO     , nil } ) 
         EndIf 
         
         //========================================================================
         // Dados Cadastrais
         //========================================================================
         If MV_PAR01 == 1 .And. ! Empty(ZBG->ZBG_EST) // MV_PAR04
            aAdd( _aDadosFor , {	"A2_EST"		   , AllTrim(ZBG->ZBG_EST)	  , nil } )
         EndIf 

         If MV_PAR02 == 1 .And. ! Empty(ZBG->ZBG_CODMUN) // MV_PAR05
            aAdd( _aDadosFor , {	"A2_COD_MUN"	, AllTrim(ZBG->ZBG_CODMUN) , nil } ) 
         EndIf 

         If MV_PAR03 == 1 .And. ! Empty(ZBG->ZBG_MUN)  // MV_PAR06
            aAdd( _aDadosFor , {	"A2_MUN"	      , AllTrim(ZBG->ZBG_MUN)    , nil } )                                                           
         EndIf 

         If MV_PAR04 == 1 .And. ! Empty(ZBG->ZBG_CEP)  // MV_PAR07
            aAdd( _aDadosFor , {	"A2_CEP"		   , AllTrim(ZBG->ZBG_CEP)	  , nil } )
         EndIf 

         If MV_PAR05 == 1 .And. ! Empty(ZBG->ZBG_END)  // MV_PAR08 
            aAdd( _aDadosFor , {	"A2_END"		   , AllTrim(ZBG->ZBG_END)    , nil } )
         EndIf 

         If MV_PAR06 == 1 .And. ! Empty(ZBG->ZBG_BAIRRO) // MV_PAR09
            aAdd( _aDadosFor , {	"A2_BAIRRO"		, AllTrim(ZBG->ZBG_BAIRRO) , nil } )
         EndIf 

         If MV_PAR07 == 1 .And. ! Empty(ZBG->ZBG_DDD)
            aAdd( _aDadosFor , {	"A2_DDD"		   , AllTrim(ZBG->ZBG_DDD)	  , nil } )
         EndIf 

         If MV_PAR07 == 1 .And. ! Empty(ZBG->ZBG_TEL) // MV_PAR10
            aAdd( _aDadosFor , {	"A2_TEL"		   , AllTrim(ZBG->ZBG_TEL)	  , nil } )
         EndIf

         If MV_PAR08 == 1 .And. ! Empty(ZBG->ZBG_EMAIL) // MV_PAR11
            aAdd( _aDadosFor , {	"A2_EMAIL"		, AllTrim(ZBG->ZBG_EMAIL)  , nil } )
         EndIf 

         //========================================================================
         // Dados Gestão do Leite
         //========================================================================
         If MV_PAR09 == 1 .And. ! Empty(ZBG->ZBG_LI_RO) // MV_PAR12
            aAdd( _aDadosFor , {	"A2_L_LI_RO"	,   ZBG->ZBG_LI_RO         , nil } ) // Linha/Rota    
         EndIf

         If MV_PAR10 == 1 // MV_PAR13
            If ! Empty(ZBG->ZBG_TANQ)
               aAdd( _aDadosFor , {	"A2_L_TANQ"	   ,   ZBG->ZBG_TANQ          , nil } ) //     Cod.Tanque	  
            EndIf 

            If ! Empty(ZBG->ZBG_TANLJ)
               aAdd( _aDadosFor , {	"A2_L_TANLJ"	,   ZBG->ZBG_TANLJ         , nil } ) //    Loja Tanque   
            EndIf
         EndIf 
        
         If MV_PAR11 == 1 .And. ! Empty(ZBG->ZBG_NIRF)  // MV_PAR15
            aAdd( _aDadosFor , {	"A2_L_NIRF"	   ,   ZBG->ZBG_NIRF          , nil } ) //     Nr.ITR/NIRF   
         EndIf 
         
         If MV_PAR12 == 1 .And. ! Empty(ZBG->ZBG_ATIVO)  // MV_PAR16
            aAdd( _aDadosFor , {	"A2_L_ATIVO"	,   ZBG->ZBG_ATIVO         , nil } ) //    Ativo         
         EndIf 

         If MV_PAR13 == 1 .And.  ! Empty(ZBG->ZBG_CLASS)  // MV_PAR17
            aAdd( _aDadosFor , {	"A2_L_CLASS"	,   ZBG->ZBG_CLASS         , nil } ) //    Classif.	     
         EndIf 

         If MV_PAR14 == 1 .And. ! Empty(ZBG->ZBG_MARTQ)  // MV_PAR18
            aAdd( _aDadosFor , {	"A2_L_MARTQ"	,   ZBG->ZBG_MARTQ         , nil } ) //    Marca do TQ   
         EndIf 

         If MV_PAR15 == 1 .And. ! Empty(ZBG->ZBG_RESFR) // MV_PAR19
            aAdd( _aDadosFor , {	"A2_L_RESFR"	,   ZBG->ZBG_RESFR         , nil } ) //    Resfriamento  
         EndIf 

         If MV_PAR16 == 1 .And. ! Empty(ZBG->ZBG_CAPAC) // MV_PAR20
            aAdd( _aDadosFor , {	"A2_L_CAPAC"	,   ZBG->ZBG_CAPAC         , nil } ) //    Cap. Resfri.  
         EndIf

         If MV_PAR17 = 1 .And.  ! Empty(ZBG->ZBG_CAPTQ) // MV_PAR21
            aAdd( _aDadosFor , {	"A2_L_CAPTQ"	,   ZBG->ZBG_CAPTQ         , nil } ) //    Cap. Tanque   
         EndIf 

         If MV_PAR18 == 1 .And. ! Empty(ZBG->ZBG_FAZEN)  //MV_PAR22
            aAdd( _aDadosFor , {	"A2_L_FAZEN"	,   ZBG->ZBG_FAZEN         , nil } ) //    Fazenda       
         EndIf 
         
         If  MV_PAR19 == 1 .And. ! Empty(ZBG->ZBG_FREQU)  // MV_PAR23
            aAdd( _aDadosFor , {	"A2_L_FREQU"	,   ZBG->ZBG_FREQU         , nil } ) //    Freq. Coleta  
         EndIf 

         If  MV_PAR20 == 1 .And. ! Empty(ZBG->ZBG_LONGI)  //  MV_PAR24
            aAdd( _aDadosFor , {	"A2_L_LONGI"	,   ZBG->ZBG_LONGI         , nil } ) //    Longitude     
         EndIf 

         If  MV_PAR21 == 1 .And. ! Empty(ZBG->ZBG_LATIT)  // MV_PAR25
            aAdd( _aDadosFor , {	"A2_L_LATIT"	,   ZBG->ZBG_LATIT         , nil } ) //    Latitude      
         EndIf  

         If MV_PAR22 == 1 .And. Empty(ZBG->ZBG_BANCO)
            aAdd( _aDadosFor , {	"A2_BANCO"	   ,   ZBG->ZBG_BANCO         , nil } ) //    Banco
         EndIf 

         If MV_PAR23 == 1 .And. Empty(ZBG->ZBG_AGENCI)
            aAdd( _aDadosFor , {	"A2_AGENCIA"	,   ZBG->ZBG_AGENCI        , nil } ) //    Agencia
         EndIf 

         If MV_PAR24 == 1 .And. Empty(ZBG->ZBG_NUMCON)
            aAdd( _aDadosFor , {	"A2_NUMCON"	   ,   ZBG->ZBG_NUMCO         , nil } ) //    Numero Conta
         EndIf 
         
         lMSErroAuto := .F.
       
         If _lIncluir
            MSExecAuto( {|x,y| Mata020(x,y) } , _aDadosFor , 3 )
	      Else
            MSExecAuto( {|x,y| Mata020(x,y) } , _aDadosFor , 4 )   
         EndIf 

         If lMSErroAuto
            If _lIncluir
               U_ITMsg("Não foi possivel incluir o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
            Else 
               U_ITMsg("Não foi possivel alterar o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
            EndIf 

	         Mostraerro()
         Else  

            ZBG->(RecLock("ZBG",.F.))
            ZBG->ZBG_STATUS := "A"
            ZBG->ZBG_USRAPR := _cNomeUser	// Usuário Altualiz.Cad.Produtor
            ZBG->ZBG_DTAPR	 := Date()     // Atualiz.Cad. Produtor
            ZBG->ZBG_HRAPR	 := Time()     // Hora Atualiz.Cad.Produtor
            ZBG->(MSUnLock())
            
            (cAliasAux)->ZBG_STATUS := "A"

	      EndIf				

      EndIf

      (cAliasAux)->(DBSkip())
   EndDo
   
   (cAliasAux)->(DBGoTop())

   _oMarkBRW:Refresh()

   U_ITMsg("Atualização de Produtores Finalizada...","Atenção",,2)

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AGLT055T
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Função chamada detro da transação de gravação da função AxAltera, no momento da gravação da tabela
                    ZBG.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055T()
Local _cNomeUser := UsrFullName(__cUserId)

Begin Sequence 

   ZBG->(RecLock("ZBG",.F.))
   ZBG->ZBG_USRALT := _cNomeUser	// Usuário da Alteração
   ZBG->ZBG_DTALT	 := Date()   // Data da Alteração
   ZBG->ZBG_HRALT	 := Time()   // Hora da Alteração
   ZBG->(MSUnLock())

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AGLT055V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os Produtores Rejeitados e Aceitos no Envio de Dados para a Cia do Leite.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT055V(_cTipoDado)
Local _aSizeAut   := MsAdvSize(.T.)
Local _cTitulo    As char

Private aRotina := {}
Private cCadastro As char
Private aHeader := {}
Private _oGetDB As object
Private _lFinalizar  := .F.

Begin Sequence 

   //======================================================
   // Configurações iniciais
   //======================================================
   _aObjects := {} 
   aAdd( _aObjects, { 315,  50, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 

   aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
	aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
	aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
	aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
	aAdd(aRotina,{"Excluir"		,"AxExclui",0,5})
   Inclui := .F.
   Altera := .T.

   If _cTipoDado == "A"
      _cTitulo := "Produtores Aceitos no Envio de Dados para o Sistema Cia do Leite"
      _cAliasTrb := "TRBZBHA"
   Else 
      _cTitulo := "Produtores Rejeitados no Envio de Dados para o Sistema Cia do Leite"  
      _cAliasTrb := "TRBZBHR"
   EndIf 

   //======================================================
   // Monta o AHeader para o MSGETDB.
   //======================================================
   // aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})

   aAdd(aHeader,{"Filial"                              ,;   // 1  = X3_TITULO                   
                 "ZBH_FILIAL"                          ,;   // 2  = X3_CAMPO
                 ""                                    ,;   // 3  = X3_PICTURE                    
                 1                                     ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                     ,;  // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX

   aAdd(aHeader,{"Descrição"                            ,;   // 1  = X3_TITULO                   
                 "ZZM_DESCRI"                          ,;   // 2  = X3_CAMPO
                 getsx3cache("ZZM_DESCRI","X3_PICTURE"),;   // 3  = X3_PICTURE                    
                 30                                     ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                    ,;   // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX

    aAdd(aHeader,{"Cod.Produtor"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_CODPRO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Loj.Produtor"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_LOJPRO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX
   
   aAdd(aHeader,{"Nome Produtor"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_NOMPRO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       60              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Data Rejeic"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_DTREJ"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "D"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX


   aAdd(aHeader,{"Hora Rejeic"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_HRREJ"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX


   aAdd(aHeader,{"Data Envio"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_DTENV"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "D"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Hora Envio"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_HRENV"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "D"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Status Integra"                       ,;   // 1  = X3_TITULO                   
                            "ZBH_STATUS"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       20              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                    getsx3cache("ZZM_DESCRI","X3_CBOX")})                  // 10 = X3_CBOX                                      
     
    (_cAliasTrb)->(DBGoTop())
    While .T.

       DEFINE MSDIALOG _oDlgPrd TITLE _cTitulo FROM _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL // 00,00 TO 300,400
           @ _aPosObj[2,3]-30, 05  BUTTON _OButtonApr PROMPT "&Visualizar" SIZE 50, 012 OF _oDlgPrd ACTION (U_AGLT055J( (_cAliasTrb)->WK_RECNO , _cTipoDado) ) PIXEL
	        @ _aPosObj[2,3]-30, 60  BUTTON _OButtonRej PROMPT "&Pesquisar"  SIZE 50, 012 OF _oDlgPrd ACTION (U_AGLT055P()) PIXEL
	        @ _aPosObj[2,3]-30, 115 BUTTON _OButtonRej PROMPT "&Gera Excel" SIZE 50, 012 OF _oDlgPrd ACTION EVAL(_bExcel) PIXEL
           @ _aPosObj[2,3]-30, 170 BUTTON _OButtonGrv PROMPT "&Sair"	      SIZE 50, 012 OF _oDlgPrd ACTION (_lFinalizar := .T., _oDlgPrd:End() ) PIXEL  
                    //MsGetDB():New ( < nTop>, < nLeft>, < nBottom>       , < nRight>        ,< nOpc>, [ cLinhaOk]  , [ cTudoOk]  ,[ cIniCpos], [ lDelete], [ aAlter]                   , [ nFreeze], [ lEmpty], [ uPar1], < cTRB>  , [ cFieldOk] , [ uPar2], [ lAppend], [ oWnd], [ lDisparos], [ uPar3], [ cDelOk], [ cSuperDel] ) --> oObj
           _oGetDB := MsGetDB():New (0       ,0        , _aPosObj[2,3]-40 , _aPosObj[2,4]    , 4     , "U_AGLT055D" , "U_AGLT055D", ""         , .F.       , {} , 0         , .F.       ,        , _cAliasTrb, "U_AGLT055D",         , .F.       , _oDlgPrd, .T.        ,         ,""        , "")
           _oGetDB:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb()
           _oGetDB:Enable( ) 

           (_cAliasTrb)->(DBGoTop())
           _oGetDB:ForceRefresh()

       ACTIVATE MSDIALOG _oDlgPrd CENTERED
        
       If _lFinalizar
          Exit
       EndIf

    EndDo 

End Sequence 

Return    

/*
===============================================================================================================================
Programa----------: AGLT055F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/02/2022
Descrição---------: Rejeita os dados do Produtor recebidos na integração com os sistema da companhia do leite.
                    Os dados do cadastro de produtor não será atualizado com estas informações.
Parametros--------: nRegZBG = Recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055F(nRegZBG)

Begin Sequence 
   
   If Empty(nRegZBG)
      Break 
   EndIf 

   If U_ITMsg("Confirma a rejeição dos dados do Produtor posicionado?","Atenção" , , ,2, 2)
      
      ZBG->(DBGoTo((cAliasAux)->WK_RECNO))
      ZBG->(RecLock("ZBG",.F.))
      ZBG->ZBG_STATUS := "R"
      ZBG->(MSUnLock())

      (cAliasAux)->ZBG_STATUS := "R"
    
      _oMarkBRW:Refresh()
      
      U_ITMsg("Rejeição de Produtor concluida com sucesso.","Atenção",,2)
   
   Else 
      
      U_ITMsg("Rejeição de Produtor cancelada.","Atenção",,2)

   EndIf 

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AGLT055N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/03/2022
Descrição---------: Cria as tabelas de Work e carrega os dados para consultas das integrações Produtores e Coletas de Leite.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055N()
Local _aStruct, _aStruct2

Begin Sequence 

   If Select("TRBZBHA") > 0
	   TRBZBHA->(DBCloseArea())
   EndIf 
   
   If Select("TRBZBHR") > 0
	   TRBZBHR->(DBCloseArea())
   EndIf 

   If Select("TRBZBIA") > 0
	   TRBZBIA->(DBCloseArea())
   EndIf 

   If Select("TRBZBIR") > 0
	   TRBZBIR->(DBCloseArea())
   EndIf 

   If Select("QRYZBI") > 0
	   QRYZBI->(DBCloseArea())
   EndIf 

   If Select("QRYZBH") > 0
	   QRYZBH->(DBCloseArea())
   EndIf 

   _aStruct := {}
   aAdd( _aStruct , {"ZBH_FILIAL","C",	2,	0} ) //	Filial
   aAdd( _aStruct , {"ZZM_DESCRI","C",30, 0} ) //	Descrição 
   aAdd( _aStruct , {"ZBH_CODPRO","C",	6,	0} ) //	Cod.Produtor
   aAdd( _aStruct , {"ZBH_LOJPRO","C",	4,	0} ) //	Loj.Produtor
   aAdd( _aStruct , {"ZBH_NOMPRO","C",60,	0} ) //	Nome Produt
   //aAdd( _aStruct , {"ZBH_MOTIVO","M",10,	0} ) //	Motivo Rej
   aAdd( _aStruct , {"ZBH_DTREJ" ,"D",	8,	0} ) //	Data Rejeic
   aAdd( _aStruct , {"ZBH_HRREJ" ,"C",	8,	0} ) //	Hora Rejeic
   //aAdd( _aStruct , {"ZBH_JSONEN","M",	10,0} ) //	Json Envio
   aAdd( _aStruct , {"ZBH_DTENV" ,"D",	8,	0} ) //	Data Envio
   aAdd( _aStruct , {"ZBH_HRENV" ,"C",	8,	0} ) //	Hora Envio
   aAdd( _aStruct , {"ZBH_STATUS","C",	1,	0} ) //	Status Integra
   aAdd( _aStruct , {"WK_RECNO"  ,"N",	10,0} ) //  Recno ZBH
				
   //===========================================================================
   // Cria a tabela de Work TRBZBHA.
   //===========================================================================
   _otemp2 := FWTemporaryTable():New( "TRBZBHA", _aStruct)
   _otemp2:AddIndex( "01", {"ZBH_FILIAL","ZBH_DTENV","ZBH_CODPRO"})
   _otemp2:AddIndex( "02", {"ZBH_FILIAL","ZBH_DTENV","ZBH_NOMPRO"})
   _otemp2:AddIndex( "03", {"ZBH_FILIAL","ZBH_DTENV","ZBH_HRENV","ZBH_CODPRO"})
   _otemp2:AddIndex( "04", {"ZBH_CODPRO","ZBH_DTENV"})
   _otemp2:AddIndex( "05", {"ZBH_NOMPRO","ZBH_DTENV"})
   _otemp2:AddIndex( "06", {"ZBH_DTENV" ,"ZBH_HRENV","ZBH_CODPRO"})

   _otemp2:Create()

   //===========================================================================
   // Cria a tabela de Work TRBZBHR.
   //===========================================================================
   _otemp3 := FWTemporaryTable():New( "TRBZBHR", _aStruct)
   _otemp3:AddIndex( "01", {"ZBH_FILIAL","ZBH_DTENV","ZBH_CODPRO"})
   _otemp3:AddIndex( "02", {"ZBH_FILIAL","ZBH_DTENV","ZBH_NOMPRO"})
   _otemp3:AddIndex( "03", {"ZBH_FILIAL","ZBH_DTENV","ZBH_HRENV","ZBH_CODPRO"})
   _otemp3:AddIndex( "04", {"ZBH_CODPRO", "ZBH_DTENV"})
   _otemp3:AddIndex( "05", {"ZBH_NOMPRO", "ZBH_DTENV"})
   _otemp3:AddIndex( "06", {"ZBH_DTENV" ,"ZBH_HRENV","ZBH_CODPRO"})
   
   _otemp3:Create()

   //===========================================================================
   _aStruct2 := {}
   aAdd( _aStruct2 , {"ZBI_FILIAL","C",  2, 0}) //	Filial
   aAdd( _aStruct2 , {"ZZM_DESCRI","C", 30, 0}) //	Descrição 
   aAdd( _aStruct2 , {"ZBI_TICKET","C", 10, 0}) //	Ticket
   aAdd( _aStruct2 , {"ZBI_DTCOLE","D", 8 , 0}) //	Dt.Coleta
   aAdd( _aStruct2 , {"ZBI_CODPRO","C", 6 , 0}) //	Cod.Produtor
   aAdd( _aStruct2 , {"ZBI_LOJPRO","C", 4 , 0}) //	Loj.Produtor
   aAdd( _aStruct2 , {"ZBI_NOMPRO","C", 60, 0}) //	Nome Produt
   aAdd( _aStruct2 , {"ZBI_DTREJ" ,"D", 8 , 0}) //	Data Rejeic
   aAdd( _aStruct2 , {"ZBI_HRREJ" ,"C", 8 , 0}) //	Hora Rejeic
   //aAdd( _aStruct2 , {"ZBI_JSONEN","M", 10, 0}) //	Json Envio
   aAdd( _aStruct2 , {"ZBI_DTENV" ,"D", 8 , 0}) //	Data Envio
   aAdd( _aStruct2 , {"ZBI_HRENV" ,"C", 8 , 0}) //	Hora Envio
   aAdd( _aStruct2 , {"ZBI_STATUS","C", 1 , 0}) //	Status Integra
   aAdd( _aStruct2 , {"ZBI_MOTIVO","C",200, 0}) //	Motivo Rej
   aAdd( _aStruct2 , {"WK_RECNO"  ,"N", 10, 0}) //  Recno ZBH
   aAdd( _aStruct2 , {"WK_L_ATIVO","C",10 ,0})  // situacao  // Ativo / Inativo
   //===========================================================================
   // Cria a tabela de Work TRBZBIA.
   //===========================================================================
   _otemp4 := FWTemporaryTable():New( "TRBZBIA", _aStruct2)
   
   _otemp4:AddIndex( "01", {"ZBI_FILIAL","ZBI_DTENV","ZBI_TICKET"})
   _otemp4:AddIndex( "02", {"ZBI_FILIAL","ZBI_DTENV","ZBI_CODPRO"})
   _otemp4:AddIndex( "03", {"ZBI_FILIAL","ZBI_DTENV","ZBI_NOMPRO"})
   _otemp4:AddIndex( "04", {"ZBI_FILIAL","ZBI_DTENV","ZBI_HRENV","ZBI_CODPRO"})
   _otemp4:AddIndex( "05", {"ZBI_CODPRO","ZBI_DTENV"})
   _otemp4:AddIndex( "06", {"ZBI_NOMPRO","ZBI_DTENV"})
   _otemp4:AddIndex( "07", {"ZBI_DTENV" ,"ZBI_HRENV","ZBI_CODPRO"})
   _otemp4:AddIndex( "08", {"ZBI_TICKET","ZBI_DTENV","ZBI_FILIAL"})

   _otemp4:Create()

   //===========================================================================
   // Cria a tabela de Work TRBZBIR.
   //===========================================================================
   _otemp5 := FWTemporaryTable():New( "TRBZBIR", _aStruct2)
   
   _otemp5:AddIndex( "01", {"ZBI_FILIAL","ZBI_DTENV","ZBI_TICKET"})
   _otemp5:AddIndex( "02", {"ZBI_FILIAL","ZBI_DTENV","ZBI_CODPRO"})
   _otemp5:AddIndex( "03", {"ZBI_FILIAL","ZBI_DTENV","ZBI_NOMPRO"})
   _otemp5:AddIndex( "04", {"ZBI_FILIAL","ZBI_DTENV","ZBI_HRENV","ZBI_CODPRO"})
   _otemp5:AddIndex( "05", {"ZBI_CODPRO","ZBI_DTENV"})
   _otemp5:AddIndex( "06", {"ZBI_NOMPRO","ZBI_DTENV"})
   _otemp5:AddIndex( "07", {"ZBI_DTENV" ,"ZBI_HRENV","ZBI_CODPRO"})
   _otemp5:AddIndex( "08", {"ZBI_TICKET","ZBI_DTENV","ZBI_FILIAL"})

   _otemp5:Create()

   //==============================================================
   // Query dos produtores aceitos na integração. 
   //==============================================================
   _cQryp := " SELECT "
   _cQryp += " ZBH_FILIAL, " //	Filial
   _cQryp += " ZZM_DESCRI, " // Nome da Filial do Produtor
   _cQryp += " ZBH_CODPRO, " //	Cod.Produtor
   _cQryp += " ZBH_LOJPRO, " //	Loj.Produtor
   _cQryp += " ZBH_NOMPRO, " //	Nome Produt
   _cQryp += " ZBH_MOTIVO, " //	Motivo Rej
   _cQryp += " ZBH_DTREJ, "  //	Data Rejeic
   _cQryp += " ZBH_HRREJ, "  //	Hora Rejeic
   _cQryp += " ZBH_JSONEN, " //	Json Envio
   _cQryp += " ZBH_DTENV, "  //	Data Envio
   _cQryp += " ZBH_HRENV, "  //	Hora Envio
   _cQryp += " ZBH_STATUS, " //	Status Integra
   _cQryp += " ZBH.R_E_C_N_O_	AS REGZBH "
   _cQryp += " FROM  "+ RetSqlName("ZBH") +" ZBH, " + RetSqlName("ZZM") +" ZZM "
   _cQryp += " WHERE "
   _cQryp += "     ZBH.D_E_L_E_T_  = ' ' AND ZZM.D_E_L_E_T_  = ' ' AND ZBH_STATUS = 'A' "
   _cQryp += " AND ZBH_FILIAL = ZZM_CODIGO "

   If ! Empty(MV_PAR01)
      _cQryp += " AND ZBH_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
   EndIf 

   If ! Empty(MV_PAR02)
      _cQryP += " AND ZBH_DTENV >= '"+ DToS(MV_PAR02) + "' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQryP += " AND ZBH_DTENV <= '"+ DToS(MV_PAR03) + "' "
   EndIf 

   If Type("cFiltroZBH") = "C" .And. !Empty(cFiltroZBH)
      _cQryP += cFiltroZBH
   EndIf       
   
   _cQryP += " ORDER BY ZBH_DTENV, ZBH_CODPRO "

   ProcRegua(0)
   IncProc( "Lendo dados dos Produtores..." )

   If Select("QRYZBH") > 0
      QRYZBH->( DBCloseArea() )
   EndIf 

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQryP) , "QRYZBH" , .T. , .F. )
   
   TCSetField('QRYZBH',"ZBH_DTREJ","D",8,0)
   TCSetField('QRYZBH',"ZBH_DTENV","D",8,0)

   DBSelectArea("QRYZBH")
   QRYZBH->( DBGoTop() )
   COUNT TO _nTotReg

   DBSelectArea( cAliasAux )
   ProcRegua(_nTotReg)

   QRYZBH->( DBGoTop() )
   While QRYZBH->( !Eof() )
      
      IncProc( "Lendo dados dos Produtores aceitos..." )

      TRBZBHA->( DBAPPEND() )
      TRBZBHA->ZBH_FILIAL := QRYZBH->ZBH_FILIAL //	Filial
      TRBZBHA->ZZM_DESCRI := QRYZBH->ZZM_DESCRI //	Descrição 
      TRBZBHA->ZBH_CODPRO := QRYZBH->ZBH_CODPRO //	Cod.Produtor
      TRBZBHA->ZBH_LOJPRO := QRYZBH->ZBH_LOJPRO //	Loj.Produtor
      TRBZBHA->ZBH_NOMPRO := QRYZBH->ZBH_NOMPRO //	Nome Produt
      TRBZBHA->ZBH_DTREJ  := QRYZBH->ZBH_DTREJ  //	Data Rejeic
      TRBZBHA->ZBH_HRREJ  := QRYZBH->ZBH_HRREJ  //	Hora Rejeic
      TRBZBHA->ZBH_DTENV  := QRYZBH->ZBH_DTENV  //	Data Envio
      TRBZBHA->ZBH_HRENV  := QRYZBH->ZBH_HRENV  //	Hora Envio
      TRBZBHA->ZBH_STATUS := QRYZBH->ZBH_STATUS  //	Status Integra
      TRBZBHA->WK_RECNO   := QRYZBH->REGZBH     //  Recno ZBH

      QRYZBH->( DBSkip() )
		
   EndDo

   //QRYZBH->( DBCloseArea() )
   If Select("QRYZBH") > 0
      QRYZBH->( DBCloseArea() )
   EndIf 

   //==============================================================
   // Query dos produtores rejeitados na integração. 
   //==============================================================
   _cQryp := " SELECT "
   _cQryp += " ZBH_FILIAL, " //	Filial
   _cQryp += " ZZM_DESCRI, " // Nome da Filial do Produtor
   _cQryp += " ZBH_CODPRO, " //	Cod.Produtor
   _cQryp += " ZBH_LOJPRO, " //	Loj.Produtor
   _cQryp += " ZBH_NOMPRO, " //	Nome Produt
   _cQryp += " ZBH_MOTIVO, " //	Motivo Rej
   _cQryp += " ZBH_DTREJ, "  //	Data Rejeic
   _cQryp += " ZBH_HRREJ, "  //	Hora Rejeic
   _cQryp += " ZBH_JSONEN, " //	Json Envio
   _cQryp += " ZBH_DTENV, "  //	Data Envio
   _cQryp += " ZBH_HRENV, "  //	Hora Envio
   _cQryp += " ZBH_STATUS, " //	Status Integra
   _cQryp += " ZBH.R_E_C_N_O_	AS REGZBH "
   _cQryp += " FROM  "+ RetSqlName("ZBH") +" ZBH, " + RetSqlName("ZZM") +" ZZM "
   _cQryp += " WHERE "
   _cQryp += "     ZBH.D_E_L_E_T_  = ' ' AND ZZM.D_E_L_E_T_  = ' ' AND ZBH_STATUS = 'R' "
   _cQryp += " AND ZBH_FILIAL = ZZM_CODIGO "

   If ! Empty(MV_PAR01)
      _cQryp += " AND ZBH_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
   EndIf 

   If ! Empty(MV_PAR02)
      _cQryP += " AND ZBH_DTENV >= '"+ DToS(MV_PAR02) + "' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQryP += " AND ZBH_DTENV <= '"+ DToS(MV_PAR03) + "' "
   EndIf 

   If Type("cFiltroZBH") = "C" .And. !Empty(cFiltroZBH)
      _cQryP += cFiltroZBH
   EndIf       
   
   _cQryP += " ORDER BY ZBH_DTENV, ZBH_CODPRO "

   If Select("QRYZBH") > 0
      QRYZBH->( DBCloseArea() )
   EndIf 

   ProcRegua(0)
   IncProc( "Lendo dados dos Produtores..." )
   
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQryP) , "QRYZBH" , .T. , .F. )
   
   TCSetField('QRYZBH',"ZBH_DTREJ","D",8,0)
   TCSetField('QRYZBH',"ZBH_DTENV","D",8,0)

   DBSelectArea("QRYZBH")
   QRYZBH->( DBGoTop() )
   COUNT TO _nTotReg

   DBSelectArea( cAliasAux )
   ProcRegua(_nTotReg)

   QRYZBH->( DBGoTop() )
   While QRYZBH->( !Eof() )
      
      IncProc( "Lendo dados dos Produtores rejeitados..." )

      TRBZBHR->( DBAPPEND() )
      TRBZBHR->ZBH_FILIAL := QRYZBH->ZBH_FILIAL //	Filial
      TRBZBHR->ZZM_DESCRI := QRYZBH->ZZM_DESCRI //	Descrição 
      TRBZBHR->ZBH_CODPRO := QRYZBH->ZBH_CODPRO //	Cod.Produtor
      TRBZBHR->ZBH_LOJPRO := QRYZBH->ZBH_LOJPRO //	Loj.Produtor
      TRBZBHR->ZBH_NOMPRO := QRYZBH->ZBH_NOMPRO //	Nome Produt
      TRBZBHR->ZBH_DTREJ  := QRYZBH->ZBH_DTREJ  //	Data Rejeic
      TRBZBHR->ZBH_HRREJ  := QRYZBH->ZBH_HRREJ  //	Hora Rejeic
      TRBZBHR->ZBH_DTENV  := QRYZBH->ZBH_DTENV  //	Data Envio
      TRBZBHR->ZBH_HRENV  := QRYZBH->ZBH_HRENV  //	Hora Envio
      TRBZBHR->ZBH_STATUS := QRYZBH->ZBH_STATUS //	Status Integra
      TRBZBHR->WK_RECNO   := QRYZBH->REGZBH     //  Recno ZBH

      QRYZBH->( DBSkip() )
		
   EndDo

   //QRYZBH->( DBCloseArea() )
   If Select("QRYZBH") > 0
      QRYZBH->( DBCloseArea() )
   EndIf
   //==============================================================
   // Query das coletas aceitas na integração.
   //==============================================================
   _cQryc := " SELECT "
   _cQryc += " ZBI_FILIAL, "  //	Filial
   _cQryc += " ZZM_DESCRI, "  //	Descrição 
   _cQryc += " ZBI_TICKET, "  //	Ticket
   _cQryc += " ZBI_DTCOLE, "  //	Dt.Coleta
   _cQryc += " ZBI_CODPRO, "  //	Cod.Produtor
   _cQryc += " ZBI_LOJPRO, "  //	Loj.Produtor
   _cQryc += " ZBI_NOMPRO, "  //	Nome Produt
   _cQryc += " ZBI_DTREJ, "   //	Data Rejeic
   _cQryc += " ZBI_HRREJ, "   //	Hora Rejeic
   _cQryc += " ZBI_DTENV, "   //	Data Envio
   _cQryc += " ZBI_HRENV, "   //	Hora Envio
   _cQryc += " ZBI_STATUS, "  //	Status Integra
   _cQryc += " ZBI.R_E_C_N_O_	AS REGZBI "
   _cQryc += " FROM  "+ RetSqlName("ZBI") +" ZBI, " + RetSqlName("ZZM") +" ZZM "
   _cQryc += " WHERE "
   _cQryc += "     ZBI.D_E_L_E_T_  = ' ' AND ZZM.D_E_L_E_T_  = ' ' AND ZBI_STATUS = 'A' "
 
   _cQryc += " AND ZBI_FILIAL = ZZM_CODIGO "
   
   If ! Empty(MV_PAR01)
      _cQryc += " AND ZBI_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
   EndIf 

   If ! Empty(MV_PAR02)
      _cQryc += " AND ZBI_DTENV >= '"+ DToS(MV_PAR02) + "' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQryc += " AND ZBI_DTENV <= '"+ DToS(MV_PAR03) + "' "
   EndIf 

   If Type("cFiltroZBI") = "C" .And. !Empty(cFiltroZBI)
      _cQryc += cFiltroZBI
   EndIf       
   
   _cQryc += " ORDER BY ZBI_DTENV, ZBI_CODPRO "

   If Select("QRYZBI") > 0
      QRYZBI->( DBCloseArea() )
   EndIf 

   ProcRegua(0)
   IncProc( "Lendo dados das Coletas de Leite aceitas..." )
   
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQryc) , "QRYZBI" , .T. , .F. )
   
   TCSetField('QRYZBI',"ZBI_DTREJ" ,"D",8,0)
   TCSetField('QRYZBI',"ZBI_DTENV" ,"D",8,0)
   TCSetField('QRYZBI',"ZBI_DTCOLE","D",8,0)

   DBSelectArea("QRYZBI")
   QRYZBI->( DBGoTop() )
   COUNT TO _nTotReg

   DBSelectArea( "QRYZBI" )
   ProcRegua(_nTotReg)

   QRYZBI->( DBGoTop() )
   While QRYZBI->( !Eof() )
         
      IncProc( "Lendo dados das Coletas de Leite Aceitas..." )
      
      TRBZBIA->( DBAPPEND())
      TRBZBIA->ZBI_FILIAL := QRYZBI->ZBI_FILIAL   //	Filial
      TRBZBIA->ZZM_DESCRI := QRYZBI->ZZM_DESCRI   //	Descrição 
      TRBZBIA->ZBI_TICKET := QRYZBI->ZBI_TICKET   //	Ticket
      TRBZBIA->ZBI_DTCOLE := QRYZBI->ZBI_DTCOLE   //	Dt.Coleta
      TRBZBIA->ZBI_CODPRO := QRYZBI->ZBI_CODPRO   //	Cod.Produtor
      TRBZBIA->ZBI_LOJPRO := QRYZBI->ZBI_LOJPRO   //	Loj.Produtor
      TRBZBIA->ZBI_NOMPRO := QRYZBI->ZBI_NOMPRO   //	Nome Produt
      TRBZBIA->ZBI_DTREJ  := QRYZBI->ZBI_DTREJ    //	Data Rejeic
      TRBZBIA->ZBI_HRREJ  := QRYZBI->ZBI_HRREJ    //	Hora Rejeic
      TRBZBIA->ZBI_DTENV  := QRYZBI->ZBI_DTENV    //	Data Envio
      TRBZBIA->ZBI_HRENV  := QRYZBI->ZBI_HRENV    //	Hora Envio
      TRBZBIA->ZBI_STATUS := QRYZBI->ZBI_STATUS   //	Status Integra
      TRBZBIA->WK_RECNO   := QRYZBI->REGZBI       //  Recno ZBI

      QRYZBI->( DBSkip() )
		
   EndDo

   If Select("QRYZBI") > 0
      QRYZBI->( DBCloseArea() )
   EndIf 

   //==============================================================
   // Query das coletas rejeitadas na integração.
   //==============================================================
   _cQryc := " SELECT "
   _cQryc += " ZBI_FILIAL, "  //	Filial
   _cQryc += " ZZM_DESCRI, "  //	Descrição 
   _cQryc += " ZBI_TICKET, "  //	Ticket
   _cQryc += " ZBI_DTCOLE, "  //	Dt.Coleta
   _cQryc += " ZBI_CODPRO, "  //	Cod.Produtor
   _cQryc += " ZBI_LOJPRO, "  //	Loj.Produtor
   _cQryc += " ZBI_NOMPRO, "  //	Nome Produt
   _cQryc += " ZBI_DTREJ, "   //	Data Rejeic
   _cQryc += " ZBI_HRREJ, "   //	Hora Rejeic
   _cQryc += " ZBI_DTENV, "   //	Data Envio
   _cQryc += " ZBI_HRENV, "   //	Hora Envio
   _cQryc += " ZBI_STATUS, "  //	Status Integra
   _cQryc += " ZBI.R_E_C_N_O_	AS REGZBI, "
   _cQryc += " ZBI_MOTIVO  "  //	Motivo da Rejeição   
   _cQryc += " FROM  "+ RetSqlName("ZBI") +" ZBI, " + RetSqlName("ZZM") +" ZZM "
   _cQryc += " WHERE "
   _cQryc += "     ZBI.D_E_L_E_T_  = ' ' AND ZZM.D_E_L_E_T_  = ' ' AND ZBI_STATUS = 'R' "
 
   _cQryc += " AND ZBI_FILIAL = ZZM_CODIGO "
   
   If ! Empty(MV_PAR01)
      _cQryc += " AND ZBI_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
   EndIf 

   If ! Empty(MV_PAR02)
      _cQryc += " AND ZBI_DTENV >= '"+ DToS(MV_PAR02) + "' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQryc += " AND ZBI_DTENV <= '"+ DToS(MV_PAR03) + "' "
   EndIf 

   If Type("cFiltroZBI") = "C" .And. !Empty(cFiltroZBI)
      _cQryc += cFiltroZBI
   EndIf       
   
   _cQryc += " ORDER BY ZBI_DTENV, ZBI_CODPRO "

   If Select("QRYZBI") > 0
      QRYZBI->( DBCloseArea() )
   EndIf 

   ProcRegua(0)
   IncProc( "Lendo dados das Coletas de Leite rejeitadas..." )
   
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQryc) , "QRYZBI" , .T. , .F. )
   
   TCSetField('QRYZBI',"ZBI_DTREJ" ,"D",8,0)
   TCSetField('QRYZBI',"ZBI_DTENV" ,"D",8,0)
   TCSetField('QRYZBI',"ZBI_DTCOLE","D",8,0)

   DBSelectArea("QRYZBI")
   QRYZBI->( DBGoTop() )
   COUNT TO _nTotReg

   DBSelectArea( "QRYZBI" )
   ProcRegua(_nTotReg)

   QRYZBI->( DBGoTop() )
   While QRYZBI->( !Eof() )
         
      IncProc( "Lendo dados das Coletas de Leite Rejeitadas..." )
      
      _cZBI_MOTIVO:=StrTran(QRYZBI->ZBI_MOTIVO,CHR(10),"")
      If (_cPosJ:=AT('"message_error": [',_cZBI_MOTIVO)) > 0
         _cZBI_MOTIVO:=SubStr(_cZBI_MOTIVO,AT('"message_error": [',_cZBI_MOTIVO)+17)
         If (_cPosJ:=AT(']',_cZBI_MOTIVO)) > 0
            _cZBI_MOTIVO:=SubStr(_cZBI_MOTIVO,1,_cPosJ)
         EndIf
      EndIf
      If Empty(_cZBI_MOTIVO)
         _cZBI_MOTIVO:=AllTrim(StrTran(QRYZBI->ZBI_MOTIVO,CHR(10)," "))
      EndIf
      
      TRBZBIR->( DBAPPEND() )
      TRBZBIR->ZBI_FILIAL := QRYZBI->ZBI_FILIAL   //	Filial
      TRBZBIR->ZZM_DESCRI := QRYZBI->ZZM_DESCRI   //	Descrição 
      TRBZBIR->ZBI_TICKET := QRYZBI->ZBI_TICKET   //	Ticket
      TRBZBIR->ZBI_DTCOLE := QRYZBI->ZBI_DTCOLE   //	Dt.Coleta
      TRBZBIR->ZBI_CODPRO := QRYZBI->ZBI_CODPRO   //	Cod.Produtor
      TRBZBIR->ZBI_LOJPRO := QRYZBI->ZBI_LOJPRO   //	Loj.Produtor
      TRBZBIR->ZBI_NOMPRO := QRYZBI->ZBI_NOMPRO   //	Nome Produt
      TRBZBIR->ZBI_DTREJ  := QRYZBI->ZBI_DTREJ    //	Data Rejeic
      TRBZBIR->ZBI_HRREJ  := QRYZBI->ZBI_HRREJ    //	Hora Rejeic
      TRBZBIR->ZBI_DTENV  := QRYZBI->ZBI_DTENV    //	Data Envio
      TRBZBIR->ZBI_HRENV  := QRYZBI->ZBI_HRENV    //	Hora Envio
      TRBZBIR->ZBI_STATUS := QRYZBI->ZBI_STATUS   //	Status Integra
      TRBZBIR->ZBI_MOTIVO := _cZBI_MOTIVO
      TRBZBIR->WK_RECNO   := QRYZBI->REGZBI       //  Recno ZBI
      TRBZBIR->WK_L_ATIVO := If(Posicione("SA2",1,xFilial("SA2")+TRBZBIR->ZBI_CODPRO+TRBZBIR->ZBI_LOJPRO,"A2_L_ATIVO")="N","Inativo","Ativo")
  
      QRYZBI->( DBSkip() )
		
   EndDo

   If Select("QRYZBI") > 0
      QRYZBI->( DBCloseArea() )
   EndIf 

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AGLT055J
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Visualizar dados dos produtore integrados com sudcesso ou rejeitados.
Parametros--------: Recno da tabela ZBH.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055J( nRegZBH , _cTipo)
Local _cFilAtual := cFilAnt

Private cCadastro := "Visualizar - Cad.Aprovação Atualiza Produtores"

Begin Sequence 

   If _cTipo == "A"
      cCadastro := "Visualizar - Produtores Aceitos no Envio de Dados para o Sistema Cia do Leite"
   Else
      cCadastro := "Visualizar - Produtores Rejeitados no Envio de Dados para o Sistema Cia do Leite"  
   EndIf 

   If Empty(nRegZBH)
      Break 
   EndIf 
   
   cFilAnt := (_cAliasTrb)->ZBH_FILIAL

   DBSelectArea("ZBH")
   ZBH->( DBGoTo(nRegZBH) )
   AxVisual( "ZBH" , nRegZBH , 2 ) 

End Sequence 

cFilAnt := _cFilAtual

Return

/*
===============================================================================================================================
Programa----------: AGLT055D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Função de validação obrigatória no MSGETDB.
Parametros--------: Recno da tabela ZBH.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055D()
Local _lRet := .T. 

Begin Sequence 
   

End Sequence

Return _lRet 

/*
===============================================================================================================================
Programa----------: AGLT055P
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Permite pesquisar tabela de muro da integração do Produtor na tela.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055P()

Local _oGet1	  := Nil 
Local _oDlgP	  := Nil 
Local _cGet1	  := Space(60)
Local _nOpca	  := 0
Local _cComboBx1  := "Data Envio"
Local _aComboBx1  := {"Data Envio","Codigo Produtor","Nome Produtor"}
Local _nRegAtu    := (_cAliasTrb)->(Recno())
Local _cPesq 

Begin Sequence 
   
   //(_cAliasTrb)->(DBSetOrder(xxx))
   
   DEFINE MSDIALOG _oDlgP TITLE "Pesquisar Produtor Integrado" FROM 178,181 TO 259,697 PIXEL

      @ 004,003 ComboBox	_cComboBx1	Items _aComboBx1 Size 213,010 OF _oDlgP PIXEL
	   @ 020,003 MsGet		_oGet1	Var _cGet1		Size 212,009 OF _oDlgP PIXEL COLOR CLR_BLACK Picture "@!"
	
	   DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlgP:End() ) OF _oDlgP
	   DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlgP:End() ) OF _oDlgP

   ACTIVATE MSDIALOG _oDlgP CENTERED

   If _nOpca == 1
      _cPesq := RTrim(_cGet1)
      If AllTrim(_cComboBx1) == AllTrim(_aComboBx1[1]) // Data Envio
         (_cAliasTrb)->(DBSetOrder(6)) 
         _cPesq := DToS(Ctod(_cPesq))
      ElseIf AllTrim(_cComboBx1) == AllTrim(_aComboBx1[2]) // "Codigo Produtor" 
         (_cAliasTrb)->(DBSetOrder(4))       
      Else // "Nome Produtor"
         (_cAliasTrb)->(DBSetOrder(5)) 
      EndIf 
   
      If ! (_cAliasTrb)->(MsSeek(_cPesq))
         U_ITMsg("Registro não encontrado.","Atenção",,1)
         (_cAliasTrb)->(DBSetOrder(1))
         (_cAliasTrb)->(DBGoTo(_nRegAtu))
      Else 
         (_cAliasTrb)->(DBSetOrder(1))
         //_oMarkBRW:Refresh()
         _oGetDB:ForceRefresh()
      EndIf 
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AGLT055Y
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os Coletas de Leite Rejeitados e Aceitos no Envio de Dados para a Cia do Leite.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT055Y(_cTipoDado)
Local _aSizeAut  := MsAdvSize(.T.)
Local _cTitulo    As char
Local _aCabecalho As array
Local _aCampos    As char
Local H           As numeric

Private aRotina := {}
Private cCadastro 
Private aHeader := {}
Private _oGetDBI
Private _lFinalizar  := .F.

Begin Sequence 

   //======================================================
   // Configurações iniciais
   //======================================================
   _aObjects := {} 
   aAdd( _aObjects, { 315,  50, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 

   aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
	aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
	aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
	aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
	aAdd(aRotina,{"Excluir"		,"AxExclui",0,5})
   Inclui := .F.
   Altera := .T.

   If _cTipoDado == "A"
      _cTitulo := "Coletas de Leite Aceitas no Envio de Dados para o Sistema Cia do Leite"
      _cAliasTrb := "TRBZBIA"
   Else 
      _cTitulo := "Coletas de Leite Rejeitadas no Envio de Dados para o Sistema Cia do Leite"  
      _cAliasTrb := "TRBZBIR"
   EndIf 

   //======================================================
   // Monta o AHeader para o MSGETDB.
   //======================================================
   // aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})

   aAdd(aHeader,{"Filial"                              ,;   // 1  = X3_TITULO                   
                 "ZBI_FILIAL"                          ,;   // 2  = X3_CAMPO
                 ""                                    ,;   // 3  = X3_PICTURE                    
                 1                                     ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                     ,;  // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX

   aAdd(aHeader,{"Descrição"                           ,;   // 1  = X3_TITULO                   
                 "ZZM_DESCRI"                          ,;   // 2  = X3_CAMPO
                 getsx3cache("ZZM_DESCRI","X3_PICTURE"),;   // 3  = X3_PICTURE                    
                 30                                    ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                    ,;   // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX

   aAdd(aHeader,{"Ticket"                              ,;   // 1  = X3_TITULO                   
                 "ZBI_TICKET"                          ,;   // 2  = X3_CAMPO
                 getsx3cache("ZBI_TICKET","X3_PICTURE"),;   // 3  = X3_PICTURE                    
                 30                                    ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                    ,;   // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX
 
    aAdd(aHeader,{"Data Coleta"                        ,;   // 1  = X3_TITULO                   
                 "ZBI_DTCOLE"                          ,;   // 2  = X3_CAMPO
                 getsx3cache("ZBI_DTCOLE","X3_PICTURE"),;   // 3  = X3_PICTURE                    
                 30                                    ,;   // 4  = X3_TAMANHO            
                 0                                     ,;   // 5  = X3_DECIMAL
                 ""                                    ,;   // 6  = X3_VALID                 
                                                     "",;   // 7  = X3_USADO
                 "C"                                   ,;   // 8  = X3_TIPO                   
                                                     "",;   // 9  = X3_CONTEXT
                 ""})                                       // 10 = X3_CBOX


    aAdd(aHeader,{"Cod.Produtor"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_CODPRO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Loj.Produtor"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_LOJPRO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX
   
   aAdd(aHeader,{"Nome Produtor"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_NOMPRO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       60              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Data Rejeic"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_DTREJ"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "D"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX


   aAdd(aHeader,{"Hora Rejeic"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_HRREJ"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX


   aAdd(aHeader,{"Data Envio"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_DTENV"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "D"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Hora Envio"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_HRENV"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       12              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "D"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Status Integra"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_STATUS"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       20              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                    getsx3cache("ZZM_DESCRI","X3_CBOX")})                  // 10 = X3_CBOX                                      

   aAdd(aHeader,{"Produtor Ativo?"                     ,;   // 1  = X3_TITULO                   
                            "WK_L_ATIVO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       10              ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

   aAdd(aHeader,{"Motivo Rejeiçao"                       ,;   // 1  = X3_TITULO                   
                            "ZBI_MOTIVO"               ,;   // 2  = X3_CAMPO
                                      ""               ,;   // 3  = X3_PICTURE                    
                                       100             ,;   // 4  = X3_TAMANHO            
                                       0               ,;   // 5  = X3_DECIMAL
                                      ""               ,;   // 6  = X3_VALID                 
                                      ""               ,;   // 7  = X3_USADO
                                     "C"               ,;   // 8  = X3_TIPO                   
                                      ""               ,;   // 9  = X3_CONTEXT
                                      ""})                  // 10 = X3_CBOX

     _aCabecalho:={}
     _aCampos   :={}
     For H := 1 TO Len(aHeader)
    	// Alinhamento: 1-Left   ,2-Center,3-Right
    	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
         //                             ,Alinhamento,Formatação, Totaliza,cPicture
         aAdd(_aCabecalho,{ aHeader[H,1],1          ,1         ,.F.      }  )
         aAdd(_aCampos   ,aHeader[H,2] )
     Next H
    //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX,oProc)
    _bExcel:={|| U_ITGEREXCEL("AGLT005_"+DToS(DATE())+"_"+StrTran(TIME(),":","")+".XLSX",,_cTitulo,"INTEGRA_COLETA",_aCabecalho,,.T.,_cAliasTrb,_aCampos,.F.,.F.,,.F.,.T.,) }
    
    (_cAliasTrb)->(DBGoTop())
    
    While .T.

       DEFINE MSDIALOG _oDlgPrd TITLE _cTitulo FROM _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL // 00,00 TO 300,400
           @ _aPosObj[2,3]-30, 05  BUTTON _OButtonApr PROMPT "&Visualizar"	 SIZE 50, 012 OF _oDlgPrd ACTION (U_AGLT055K( (_cAliasTrb)->WK_RECNO , _cTipoDado) ) PIXEL
	        @ _aPosObj[2,3]-30, 60  BUTTON _OButtonRej PROMPT "&Pesquisar"   SIZE 50, 012 OF _oDlgPrd ACTION (U_AGLT055Q()) PIXEL
	        @ _aPosObj[2,3]-30, 115 BUTTON _OButtonRej PROMPT "&Gera Excel"  SIZE 50, 012 OF _oDlgPrd ACTION EVAL(_bExcel) PIXEL
           @ _aPosObj[2,3]-30, 170 BUTTON _OButtonGrv PROMPT "&Sair"	       SIZE 50, 012 OF _oDlgPrd ACTION (_lFinalizar := .T., _oDlgPrd:End() ) PIXEL  
                    //MsGetDB():New ( < nTop>, < nLeft>, < nBottom>       , < nRight>        ,< nOpc>, [ cLinhaOk]  , [ cTudoOk]  ,[ cIniCpos], [ lDelete], [ aAlter]                   , [ nFreeze], [ lEmpty], [ uPar1], < cTRB>  , [ cFieldOk] , [ uPar2], [ lAppend], [ oWnd], [ lDisparos], [ uPar3], [ cDelOk], [ cSuperDel] ) --> oObj
           _oGetDBI := MsGetDB():New (0       ,0        , _aPosObj[2,3]-40 , _aPosObj[2,4]    , 4     , "U_AGLT055D" , "U_AGLT055D", ""         , .F.       , {} , 0         , .F.       ,        , _cAliasTrb, "U_AGLT055D",         , .F.       , _oDlgPrd, .T.        ,         ,""        , "")
           _oGetDBI:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb()
           _oGetDBI:Enable( ) 

           (_cAliasTrb)->(DBGoTop())
           _oGetDBI:ForceRefresh()

       ACTIVATE MSDIALOG _oDlgPrd CENTERED
        
       If _lFinalizar
          Exit
       EndIf

    EndDo 

End Sequence 

Return    

/*
===============================================================================================================================
Programa----------: AGLT055K
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Visualizar dados das Coletas de Leite integradas com sudcesso ou rejeitados.
Parametros--------: Recno da tabela ZBI.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055K( nRegZBI , _cTipo)
Local _cFilAtual := cFilAnt

Private cCadastro := ""

Begin Sequence 

   If _cTipo == "A"
      cCadastro := "Visualizar - Coletas de Leite Aceitas no Envio de Dados para o Sistema Cia do Leite"
   Else
      cCadastro := "Visualizar - Coletas de Leites Rejeitadas no Envio de Dados para o Sistema Cia do Leite"  
   EndIf 

   If Empty(nRegZBI)
      Break 
   EndIf 
   
   cFilAnt := (_cAliasTrb)->ZBI_FILIAL

   DBSelectArea("ZBI")
   ZBI->( DBGoTo(nRegZBI) )
   AxVisual( "ZBI" , nRegZBI , 2 ) 

End Sequence 

cFilAnt := _cFilAtual

Return

/*
===============================================================================================================================
Programa----------: AGLT055Q
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Permite pesquisar tabela de muro da integração das Coletas de Leite na tela.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT055Q()

Local _oGet1	  := Nil 
Local _oDlgP	  := Nil 
Local _cGet1	  := Space(60)
Local _nOpca	  := 0
Local _cComboBx1  := "Data Envio"
Local _aComboBx1  := {"Data Envio","Codigo Produtor","Nome Produtor","Ticket"}
Local _nRegAtu    := (_cAliasTrb)->(Recno())
Local _cPesq 

Begin Sequence 
   
   DEFINE MSDIALOG _oDlgP TITLE "Pesquisar Coleta de Leite Integrada" FROM 178,181 TO 259,697 PIXEL

      @ 004,003 ComboBox	_cComboBx1	Items _aComboBx1 Size 213,010 OF _oDlgP PIXEL
	   @ 020,003 MsGet		_oGet1	Var _cGet1		Size 212,009 OF _oDlgP PIXEL COLOR CLR_BLACK Picture "@!"
	
	   DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlgP:End() ) OF _oDlgP
	   DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlgP:End() ) OF _oDlgP

   ACTIVATE MSDIALOG _oDlgP CENTERED

   If _nOpca == 1
      _cPesq := RTrim(_cGet1)
      If AllTrim(_cComboBx1) == AllTrim(_aComboBx1[1]) // Data Envio
         (_cAliasTrb)->(DBSetOrder(7)) 
         _cPesq := DToS(Ctod(_cPesq))
      ElseIf AllTrim(_cComboBx1) == AllTrim(_aComboBx1[2]) // "Codigo Produtor" 
         (_cAliasTrb)->(DBSetOrder(5))       
      ElseIf AllTrim(_cComboBx1) == AllTrim(_aComboBx1[3]) // "Nome Produtor"
         (_cAliasTrb)->(DBSetOrder(6)) 
      Else // Ticket
         (_cAliasTrb)->(DBSetOrder(8)) 
      EndIf 
   
      If ! (_cAliasTrb)->(MsSeek(_cPesq))
         U_ITMsg("Registro não encontrado.","Atenção",,1)
         (_cAliasTrb)->(DBSetOrder(1))
         (_cAliasTrb)->(DBGoTo(_nRegAtu))
      Else 
         (_cAliasTrb)->(DBSetOrder(1))
         _oGetDBI:ForceRefresh()
      EndIf 
   EndIf

End Sequence

Return
