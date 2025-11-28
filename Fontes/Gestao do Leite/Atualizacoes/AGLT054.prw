/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |18/08/2024| Chamado 46978. Ajustar rotina Visualização dados de integração e retorno de integração Produtor. 
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.Ch"

#Define	TITULO	"Análise de Dados dos Produtores Rurais Recebidos do APP Cia do Leite"

/*
===============================================================================================================================
Programa----------: AGLT054
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Rotina de Análise dos dados dos Produtores Rurais recebidos dos app Cia do Leite.
                    Perminte a manuteção de alguns dados, atualização do cadastro de Produtores no Protheus e rejeição de 
                    dados recebidos. Chamado 38531.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054()

Begin Sequence 

   //===========================================================================
   //| Define formato de data para exibição nas telas da rotina                |
   //===========================================================================
   SET DATE FORMAT TO "DD/MM/YYYY"

   Processa( {|| AGLT054INI() } , "Processando..." , "Iniciando o processamento..." )

End Sequence 
	
Return

/*
===============================================================================================================================
Programa----------: AGLT054INI
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT054INI()

Local _aCpos		:= AGLT054CPS()
Local _aFields		:= {}
Local _cQry		:= ""
Local _cAliasQry	:= GetNextAlias()
Local _lHaDados   := .F.

Private _oMarkBRW	:= Nil
Private cAliasAux	:= GetNextAlias()
Private _nTotReg	:= 0
Private cDtIni		:= ""
Private _aRegMrk	:= {}

Begin Sequence 

   _cQry := " SELECT "
   _cQry += " ZBG_TIPREG, "	// Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
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
   _cQry += " FROM  "+ RetSqlName("ZBG") +" ZBG "
   _cQry += " WHERE "
   _cQry += "     ZBG.D_E_L_E_T_  = ' ' AND ZBG_STATUS = 'P' "
   _cQry += " AND ZBG_FILIAL = '" + xFilial("ZBG") + "' "
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
      (cAliasAux)->( RecLock( cAliasAux , .T. ) )
      (cAliasAux)->ZBG_TIPREG := If((_cAliasQry)->ZBG_TIPREG=="N","NOVO PRODUTOR","ALTERAÇÃO DE PRODUTOR")     // Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
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
      (cAliasAux)->( MSUnLock() )
		
      (_cAliasQry)->( DBSkip() )
		
   EndDo

   If ! _lHaDados
      (cAliasAux)->( RecLock( cAliasAux , .T. ) )
      (cAliasAux)->ZBG_TIPREG := If((_cAliasQry)->ZBG_TIPREG=="N","NOVO PRODUTOR","ALTERAÇÃO DE PRODUTOR")     // Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
      (cAliasAux)->ZBG_COD    := "XXXXXX"                       // Código do Produtor	
      (cAliasAux)->ZBG_LOJA   := "XXXX"                         // Loja Produtor
      (cAliasAux)->ZBG_NOME   := "SEM DADOS PARA ATUALIZAÇÃO"	 // Razão Social
      (cAliasAux)->( MSUnLock() )
   EndIf 

   (_cAliasQry)->( DBCloseArea() )

   DBSelectArea("ZBG")

   aAdd( _aFields , { "Tipo de Registro"   , {|| (cAliasAux)->ZBG_TIPREG} , "C" , "@!"                   , 0 , 22 , 0 } )     // Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
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
   _oMarkBRW:SetMenuDef( 'AGLT054' )														// Força a utilização do menu da rotina atual
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

ADD OPTION aRotina Title 'Pesquisar'                Action 'U_AGLT054S((cAliasAux)->WK_RECNO)'   OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visualizar'               Action 'U_AGLT054R((cAliasAux)->WK_RECNO)'   OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Atualizar Produtor'       Action 'U_AGLT054G((cAliasAux)->WK_RECNO)'   OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Rejeitar Dados Produtor'  Action 'U_AGLT054F((cAliasAux)->WK_RECNO)'   OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Alterar'                  Action 'U_AGLT054A((cAliasAux)->WK_RECNO)'   OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Visul.Rej.Envio Produtor' Action 'U_AGLT054V("R")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visulizar Envio Produtor' Action 'U_AGLT054V("A")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visul.Rej.Dados Coleta'   Action 'U_AGLT054Y("R")'                     OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visulizar Envio Coleta'   Action 'U_AGLT054Y("A")'                     OPERATION 2 ACCESS 0

ADD OPTION aRotina Title 'Gera Arq.Txt Produtores Ativos/Inativos'                  Action 'U_MGLT29OM("A")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Produtores Usuarios Tanques Col.'            Action 'U_MGLT29OM("B")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Produtores Mais de Uma Propriedade'          Action 'U_MGLT29OM("C")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Produtores Rejeitados nas Integrações'       Action 'U_MGLT29OM("D")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Produtores Aceitos nas Integrações'          Action 'U_MGLT29OM("E")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Coletas Rejeitadas nas Integrações'          Action 'U_MGLT29OM("F")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Coletas Aceitas nas Integrações'             Action 'U_MGLT29OM("G")' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Gera Arq.Txt Associações/Cooperativas Ativas e Inativas'  Action 'U_MGLT29OM("H")' OPERATION 2 ACCESS 0


ADD OPTION aRotina Title 'Legenda'                  Action 'U_AGLT054LEG()'                      OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT054E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Visualizar dados integrado do Produtor Posicionado.
Parametros--------: Recno da tabela ZBG.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054R( nRegZBG )

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
Programa----------: AGLT054A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Alterar dados integrados do Produtor Posicionado.                    
Parametros--------: Recno da tabela ZBG.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054A( nRegZBG )

Private cCadastro := "Cad.Aprovação Atualiza Produtores - Alteração"

Begin Sequence 
   
   If Empty(nRegZBG)
      Break 
   EndIf 

   DBSelectArea("ZBG")
   ZBG->( DBGoTo(nRegZBG) )

   //AxAltera( <cAlias>, <nReg>  , <nOpc>, <aAcho>, <aCpos>, <nColMens>, <cMensagem>, <cTudoOk>, <cTransact>, <cFunc>, <aButtons>, <aParam>, <aAuto>, <lVirtual>, <lMaximized>)
   AxAltera( "ZBG"   , nRegZBG , 4     ,        ,        ,           ,            ,          ,  "U_AGLT054T()")

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: AGLT054CPS
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/01/2022
Descrição---------: Define a criação de campos para exibição da análise
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function AGLT054CPS()

Local _aCpos := {}

Begin Sequence 

   aAdd( _aCpos , { "MARCA"		, "C" ,  2, 0 } )
   aAdd( _aCpos , { "ZBG_TIPREG"	, "C" , 22, 0 } )	// Tipo de Registro	N=Novo Produtor;A=Alteração de Produtor
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
Programa----------: AGLT054LEG()
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Função utilizada para exibir a legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054LEG()
Local _aLegenda :=	{	{"BR_VERMELHO", "Pendente Atualização"},;
		      		      {"BR_AZUL"    , "Atualizado"},;
                        {"BR_CINZA"   , "Rejeitado"}}

BrwLegenda(TITULO,"Legenda",_aLegenda)

Return

/*
===============================================================================================================================
Programa----------: AGLT054S
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Permite pesquisar um Produtor na tela.
Parametros--------: nRegZBG = Recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054S(nRegZBG)

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
Programa----------: AGLT054G
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Atualização do cadastro de Produtores Rurais.
Parametros--------: nRegZBG = recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054G(nRegZBG)
Local _cPerg := "AGLT054G"

Begin Sequence 
   
   If ! Pergunte(_cPerg, .T., "Configuração de Campos a Serem Atualizados no Cadastro Produtores")
      Break 
   EndIf

   If ! U_ITMsg("Confirma a atualização do cadastro de Produtores para os registros selecionados?","Atenção" , , ,2, 2)
      Break 
   EndIf 
    
   Processa( {|| U_AGLT054H() } , "Processando..." , "Atualizando o Cadastro de Produtores..." )

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AGLT054H
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Atualização do cadastro de Produtores Rurais.
Parametros--------: nRegZBG = Recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054H(nRegZBG)
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
            
            If ! Empty(ZBG->ZBG_COD)
               SA2->(DBSetOrder(1))
               If ! SA2->(MsSeek(xFilial("SA2")+ZBG->ZBG_COD+ZBG->ZBG_LOJA))
                  U_ITMsg("Não foi possivel Localizar o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
                  (cAliasAux)->(DBSkip())
                  Loop
               EndIf
            ElseIf ! Empty(ZBG->ZBG_CNPJ)   
               SA2->(DBSetOrder(3))
               If ! SA2->(MsSeek(xFilial("SA2")+ZBG->ZBG_CNPJ))
                  U_ITMsg("Não foi possivel Localizar o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
                  (cAliasAux)->(DBSkip())
                  Loop
               EndIf 
            Else 
               U_ITMsg("Não foi possivel Localizar o produtor: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)
               (cAliasAux)->(DBSkip())
               Loop
            EndIf 
            
            SA2->(DBSetOrder(1))

            //========================================================================
            // Dados Cadastrais
            //========================================================================
            aAdd( _aDadosFor , {	"A2_CGC"		   , SA2->A2_CGC		 , nil } )
            aAdd( _aDadosFor , {	"A2_NOME"		, SA2->A2_NOME	    , nil } ) 
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
            aAdd( _aDadosFor , {	"A2_NUMCON"	   ,   ZBG->ZBG_NUMCON        , nil } ) //    Numero Conta // aAdd( _aDadosFor , {	"A2_NUMCON"	   ,   ZBG->ZBG_NUMCO         , nil } ) //    Numero Conta
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
            
            (cAliasAux)->(RecLock((cAliasAux),.F.))
            (cAliasAux)->ZBG_STATUS := "A"
            (cAliasAux)->(MSUnLock())

            U_ITMsg("Atualização do cadastro de produtores realizada com sucesso: " + AllTrim(ZBG->ZBG_NOME)+".","Atenção",,1)

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
Programa----------: AGLT054T
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
Descrição---------: Função chamada detro da transação de gravação da função AxAltera, no momento da gravação da tabela
                    ZBG.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054T()
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
Programa----------: AGLT054V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os Produtores Rejeitados e Aceitos no Envio de Dados para a Cia do Leite.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT054V(_cTipoDado)

Private aRotina := {}
Private cCadastro 
Private _aCampos := {}

Begin Sequence 
   
   If _cTipoDado == "R"
      ZBH->(DbSetFilter( { || ZBH_STATUS == "R" }, 'ZBH_STATUS == "R"' ) )
      cCadastro := "Produtores Rejeitados no Envio de Dados para o Sistema Cia do Leite" 
   Else
      ZBH->(DbSetFilter( { || ZBH_STATUS == "A" }, 'ZBH_STATUS == "A"' ) )
      cCadastro := "Produtores Aceitos no Envio de Dados para o Sistema Cia do Leite"
   EndIf 

   ZBH->(DBGoTop())

   _aCampos := {}
   aAdd(_aCampos,"ZBH_CODPRO")
   aAdd(_aCampos,"ZBH_LOJPRO")
   aAdd(_aCampos,"ZBH_NOMPRO")
   aAdd(_aCampos,"ZBH_MOTIVO")
   aAdd(_aCampos,"ZBH_DTREJ")
   aAdd(_aCampos,"ZBH_HRREJ") 
   aAdd(_aCampos,"ZBH_JSONEN")
   aAdd(_aCampos,"ZBH_DTENV") 
   aAdd(_aCampos,"ZBH_HRENV")
   aAdd(_aCampos,"ZBH_STATUS")

   aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"                     ,"U_AGLT054W('ZBH', _aCampos, cCadastro)" ,0,2})

   DBSelectArea("ZBH")
   ZBH->(DBSetOrder(1)) 
   ZBH->(DBGoTop())
      
   MBrowse(6,1,22,75,"ZBH")

   ZBH->(DBClearFilter())

End Sequence 

Return    

/*
===============================================================================================================================
Programa----------: AGLT054Y
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/02/2022
Descrição---------: Permite Visualizar os dados das Coletas Rejeitadas no Envio de Dados para a Cia do Leite.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AGLT054Y(_cTipoDado)

Private aRotina := {}
Private cCadastro 
Private _aCampos := {}

Begin Sequence 
   
   If _cTipoDado == "R"
      ZBI->(DbSetFilter( { || ZBI_STATUS == "R" }, 'ZBI_STATUS == "R"' ) )
      cCadastro := "Dados das Coletas Rejeitadas no Envio de Dados para o Sistema Cia do Leite"
   Else
      ZBI->(DbSetFilter( { || ZBI_STATUS == "A" }, 'ZBI_STATUS == "A"' ) )
      cCadastro := "Dados das Coletas Aceitas no Envio de Dados para o Sistema Cia do Leite"
   EndIf 

   _aCampos := {}
   aAdd(_aCampos,"ZBI_TICKET")
   aAdd(_aCampos,"ZBI_DTCOLE")
   aAdd(_aCampos,"ZBI_CODPRO")
   aAdd(_aCampos,"ZBI_LOJPRO")
   aAdd(_aCampos,"ZBI_NOMPRO")
   aAdd(_aCampos,"ZBI_MOTIVO") 
   aAdd(_aCampos,"ZBI_DTREJ")
   aAdd(_aCampos,"ZBI_HRREJ") 
   aAdd(_aCampos,"ZBI_JSONEN")
   aAdd(_aCampos,"ZBI_DTENV")
   aAdd(_aCampos,"ZBI_HRENV")
   aAdd(_aCampos,"ZBI_STATUS")

   ZBI->(DBGoTop())

   aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"                     ,"U_AGLT054W('ZBI', _aCampos, cCadastro)" ,0,2})

   DBSelectArea("ZBI")
   ZBI->(DBSetOrder(1)) 
   ZBI->(DBGoTop())
      
   MBrowse(6,1,22,75,"ZBI")

   ZBI->(DBClearFilter())

End Sequence 

Return    

/*
===============================================================================================================================
Programa----------: AGLT054F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/02/2022
Descrição---------: Rejeita os dados do Produtor recebidos na integração com os sistema da companhia do leite.
                    Os dados do cadastro de produtor não será atualizado com estas informações.
Parametros--------: nRegZBG = Recno da tabela ZBG
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT054F(nRegZBG)

Begin Sequence 
   
   If Empty(nRegZBG)
      Break 
   EndIf 

   If U_ITMsg("Confirma a rejeição dos dados do Produtor posicionado?","Atenção" , , ,2, 2)
      
      ZBG->(DBGoTo((cAliasAux)->WK_RECNO))
      ZBG->(RecLock("ZBG",.F.))
      ZBG->ZBG_STATUS := "R"
      ZBG->(MSUnLock())

      (cAliasAux)->(RecLock("ZBG",.F.))
      (cAliasAux)->ZBG_STATUS := "R"
      (cAliasAux)->(MSUnLock())
    
      _oMarkBRW:Refresh()
      
      U_ITMsg("Rejeição de Produtor concluida com sucesso.","Atenção",,2)
   
   Else 
      
      U_ITMsg("Rejeição de Produtor cancelada.","Atenção",,2)

   EndIf 

End Sequence 

Return 

/*
=================================================================================================================================
Programa--------: AGLT054W()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/04/2024
Descrição-------: Tela de Visualização dos dados de Integração Webservice Protheus x App Cia do Leite.
Parametros------: _cTab    = Alias da Tabela para Visualização dos Dados.
                  _aCampos = Campos que serão visualizados.
                  _cTitulo = Titulo da tela para a rotina que chamou a tela de visualização de dados.
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AGLT054W(_cTab, _aCampos, _cTitulo)
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel 
Local _oDlgEnch, _nI
Local _nReg := 2 , _nOpcx := 2

Private aHeader := {} , aCols := {}

Begin Sequence
  
   //================================================================================
   // Carrega os dados da tabela para visulização de dados.
   //================================================================================
   For _nI := 1 To Len(_aCampos)
       &("M->" + _aCampos[_nI]) :=  &(_cTab + "->" +_aCampos[_nI])
   Next
 
   //================================================================================
   // Monta a tela Enchoice 
   //================================================================================    
   _aObjects := {} 
   aAdd( _aObjects, { 315,  50, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 
   
   _bOk := {|| _oDlgEnch:End()}
   _bCancel := {|| _oDlgEnch:End()}
   
   Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel 
      
      EnChoice( _cTab ,_nReg, _nOpcx, , , ,_aCampos , _aPosObj[1], , 3 )
                        
   Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 

End Sequence

Return
