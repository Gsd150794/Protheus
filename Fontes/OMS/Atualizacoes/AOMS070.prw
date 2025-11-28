/*
================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
================================================================================================================================
     Autor    |    Data    |                                             Motivo                                           
=============================================================================================================================
 Lucas Borges | 14/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
 Jerry        | 01/11/2019 | Chamado 31068. Tratamento do Campo Tabela Preço no Pedido de Vendas para não validar no execauto. 
 Lucas Borges | 11/11/2019 | Chamado 31154. Retirada chamada do AOMS070X. 
 Alex Wallauer| 08/01/2020 | Chamado 31656. Alteração do tratamento do Local. 
 Igor Melgaço | 18/06/2024 | Chamado 47474. Inclusão de Campo de VR. do IPI. 
==================================================================================================================================================================================================================
 Analista     - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==================================================================================================================================================================================================================
Antonio Ramos - Igor Melgaço  - 01/10/24 - 01/10/24 - 48692   - Calculo do total do pedido.
Jerry         - Alex Wallauer - 11/10/24 - 11/10/24 - 48807   - Alteração das decimais da quantidade para 3 
Jerry         - Alex Wallauer - 16/01/25 - 20/03/25 - 49396   - Alteração para quando For produto Queijo Ralado 40g (00060034701) tratar a quantidade por múltiplos da 3UM (B1_I_QT3UM). 
Jerry         - Julio Paz     - 07/08/25 - 14/08/25 - 51673   - Ajustar cor dos textos de digitação para temas Dark e Statndard. Quando o Tema For Dark exibir texto branco. Quando For Standard exibir texto preto.
==================================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'RwMake.ch'

/*
===============================================================================================================================
Programa--------: AOMS070
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para lançamento de pedidos de vendas para funcionários.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS070()

Local _aSize   		:= MsAdvSize( .T. ) As Array
Local _aObjAux		:= {} As Array
Local _aDados		:= {} As Array

Local _oPanel		As Object
Local _oNewPag1		As Object
Local _oNewPag2		As Object
Local _oNewPag3		As Object
Local _oDlg			As Object
Local _oPanWzd		As Object
Local _oBrowse		As Object

Private _cMatric	:= "" As Char
Private _cSenha		:= "" As Char
Private _lAtivPas	:= U_ITGETMV( 'IT_ATIVPAS' , .T. ) As Logic

Private _oStepWiz	 As Object
Private _oSayL		 As Object
Private _oSayP		 As Object
Private _oSayS		 As Object

Private _oTGetL		 As Object
Private _oTGetP		 As Object
Private _oTGetS		 As Object

Private _oGrid		 As Object

Private _nLimite	:= 0 As Numeric
Private _nPedido	:= 0 As Numeric
Private _nSaldo		:= 0 As Numeric
Private _ddtoper	:= Date() As Date //ddatabase
Private _nchars		:= 6 As Numeric

Private _cLocEnt    := Space(1) As Char
Private _aLocEnt    := {" ","C=CD","E=Escritorio","O=Outro Local"} As Array

Private _oSayR		 As Object
Private _oLocRet	 As Object

Begin Sequence 
   //Se ativar parâmetro de mais de um pedido por mes 
   // e muda a profundidade de comparação de data de 6 (AAAAMM) para 8 (AAAAMMDD) passando a permitir um pedido a cada 5 dias
   If U_ItGetMV("IT_PCFUNC","N") != "N"
	  _nchars := 8
   EndIf

   If AOMS070VPV()
	  U_ITMsg(  'Não existe uma tabela de preços com período ativo para a inclusão de solicitações!' , "Atenção",,1)
	  //Return
	  Break
   EndIf


   //Grava log de execução
   u_itlogacs()

   aAdd( _aObjAux , { 100 , 100 , .T. , .T. } )

   _aInfo   := { _aSize[ 1 ] , _aSize[ 2 ] , _aSize[ 3 ] , _aSize[ 4 ] , 3 , 2 }
   _aPosAux := MsObjSize( _aInfo , _aObjAux )

   DEFINE DIALOG _oDlg TITLE 'Pedido de Compra - Funcionários' PIXEL //STYLE 128 //JPP TESTE
	
	  _oDlg:lEscClose := .F.
	
	  _oPanWzd	:= TPanel():New( 002 , 002 , "" , _oDlg ,,,,,, _aPosAux[01][04] , _aPosAux[01][03] )
	  _oStepWiz	:= FWWizardControl():New( _oPanWzd )
	
	  _oStepWiz:ActiveUISteps()
	
	  //====================================================================================================
	  // Página 01 - Identificação do funcionário
      //====================================================================================================
	  _oNewPag1 := _oStepWiz:AddStep( "1" , {|_oPanel| AOMS070P01( _oPanel , _aPosAux , @_oStepWiz ) } )
	  _oNewPag1:SetStepDescription( "Identificação do Funcionário" )											// Altera a descrição do step
	  _oNewPag1:SetNextTitle( 'Iniciar' )
	  _oNewPag1:SetNextAction( {|| AOMS070VP1( @_aDados ) } )											  		// Define o bloco ao clicar no botão Próximo
	  _oNewPag1:SetCancelAction( {|| _oDlg:End()  } )															// Define o bloco ao clicar no botão Cancelar
	
	  //====================================================================================================
	  // Pagina 02 - Montagem do pedido
	  //====================================================================================================
	  _oNewPag2 := _oStepWiz:AddStep( "2" , {|_oPanel| AOMS070P02( _oPanel , _aPosAux , @_oBrowse , _aDados ) } )
	  _oNewPag2:SetStepDescription( "Configuração do Pedido" )
	  _oNewPag2:SetNextAction( {|| AOMS070VP2( _oBrowse , @_aDados ) } )
	  _oNewPag2:SetCancelAction( {|| IIf( U_ITMsg( 'Deseja cancelar o pedido atual?' , 'Atenção!',,2,2,2 ) , ( _oDlg:End() , .F. ) , .F. ) } )	// Define o bloco ao clicar no botão Cancelar
	  _oNewPag2:SetPrevWhen( {|| .F. } )
	
	  //====================================================================================================
	  // Pagina 03 - Confirmação do pedido
	  //====================================================================================================
	  _oNewPag3 := _oStepWiz:AddStep( "3" , {|_oPanel| AOMS070P03( _oPanel , _aPosAux , _aDados ) } )
	  _oNewPag3:SetStepDescription( "Confirmação do Pedido" )
	  _oNewPag3:SetNextAction( {|| AOMS070GRV( _aDados ) , _oDlg:End() , .T. } ) 
	  _oNewPag3:SetCancelAction( {|| IIf( U_ITMsg( 'Deseja cancelar o pedido atual?' , 'Atenção!',,2,2,2 ) , ( _oDlg:End() , .F. ) , .F. ) } )	// Define o bloco ao clicar no botão Cancelar
	  _oNewPag3:SetPrevWhen( {|| .T. } )
	
	  _oStepWiz:Activate()
	
	  _oDlg:lMaximized := .T.
	
   ACTIVATE DIALOG _oDlg CENTER

   _oStepWiz:Destroy()

End Sequence

Return

/*
===============================================================================================================================
Programa--------: AOMS070P01
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para montar a página de identificação dos funcionários
===============================================================================================================================
Parametros------: 	_opanel - objeto da janela de execução
					_aposaux - array com posições da tela 
					_oStepWi - objeto do wizard de processo 
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070P01( _oPanel , _aPosAux , _oStepWiz )

Local _oTGet1	:= Nil
Local _oTGet2	:= Nil
Local _nClrText := Nil 
Local _nClrBack := Nil
Local _cTheme   := Nil 

_cTheme := totvs.framework.css.getNewWebAppTheme()
If !Empty(_cTheme) .And. _cTheme == "DARK"
	_nClrText := CLR_WHITE
	_nClrBack := CLR_BLACK
Else
	_nClrText := CLR_BLACK
	_nClrBack := CLR_WHITE
EndIf

_cMatric	:= Space( 11 )
_cSenha		:= Space( 06 )

_oSay1		:= TSay():New( 10 , ( _aPosAux[01][04] / 2 ) - 050 , {|| 'Matrícula/CPF' } , _oPanel ,,,,,, .T. ,,, 200 , 20 )
//_oTGet1		:= TGet():New( 20 , ( _aPosAux[01][04] / 2 ) - 050 , {|u| If( PCount() > 0 , _cMatric := u , _cMatric ) }	, _oPanel , 096 , 009 , "@!"  ,, 0 ,,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, _cMatric ,,,, )
_oTGet1		:= TGet():New( 20 , ( _aPosAux[01][04] / 2 ) - 050 , {|u| If( PCount() > 0 , _cMatric := u , _cMatric ) }	, _oPanel , 096 , 009 , "@!"  ,, _nClrText ,_nClrBack,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, _cMatric ,,,, )
             //TGet():New(096 ,096                             , bSetGet(cCFOP)                                         , oDialog , 060  , 008, ''    ,, nClrText, nClrBack, , , , .T., '', , , .F., .F., , .F., .F., '', 'cCFOP')
_oSay2		:= TSay():New( 40 , ( _aPosAux[01][04] / 2 ) - 050 , {|| 'Senha' }		, _oPanel ,,,,,, .T. ,,, 200 , 20 )
//_oTGet2		:= TGet():New( 50 , ( _aPosAux[01][04] / 2 ) - 050 , {|u| If( PCount() > 0 , _cSenha := u , _cSenha ) }		, _oPanel , 096 , 009 , "@K*" ,, 0 ,,, .F. ,, .T. ,, .F. , {|| _lAtivPas } , .F. , .F. ,, .F. , .T. ,, _cSenha ,,,, )
_oTGet2		:= TGet():New( 50 , ( _aPosAux[01][04] / 2 ) - 050 , {|u| If( PCount() > 0 , _cSenha := u , _cSenha ) }		, _oPanel , 096 , 009 , "@K*" ,, _nClrText ,_nClrBack,, .F. ,, .T. ,, .F. , {|| _lAtivPas } , .F. , .F. ,, .F. , .T. ,, _cSenha ,,,, )

Return
 
/*
===============================================================================================================================
Programa--------: AOMS070VP1
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para validar a identificação dos funcionários
===============================================================================================================================
Parametros------: _aDados - array e carregamento de dados de pedido já existente
===============================================================================================================================
Retorno---------: _lRet - Lógico indicando se continua ou não com inclusão/alteração de pedido
===============================================================================================================================
*/

Static Function AOMS070VP1( _aDados )

Local _lRet		:= .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _oDlgPas	:= Nil
Local _cGet1	:= Space(6)
Local _cGet2	:= Space(6)
Local _cmat2    := Space(11)
Local _nClrText := Nil 
Local _nClrBack := Nil
Local _cTheme   := Nil 

_cTheme := totvs.framework.css.getNewWebAppTheme()
If !Empty(_cTheme) .And. _cTheme == "DARK"
	_nClrText := CLR_WHITE
	_nClrBack := CLR_BLACK
Else
	_nClrText := CLR_BLACK
	_nClrBack := CLR_WHITE
EndIf

Begin Sequence
   If !(Len(AllTrim(_cMatric))==6 .Or. Len(AllTrim(_cMatric)) == 11)
	  U_ITMsg( 	'Não foi informada uma identificação de funcionário válida!','Alert', 'Verifique a Matrícula/CPF informado para iniciar.',1 )

	  //Return( .F. )
	  _lRet	:= .F.
	  Break
   EndIf

   If _lAtivPas
	  If Empty(_cSenha) .Or. Len( _cSenha ) < 6
		 U_ITMsg( 'Não foi informada uma senha de acesso válida!',"Atenção",	'A senha não pode ser em branco e tem que '		;
										 + 'ter 6 dígitos. Se o funcionário ainda'		;
										+  'não cadastrou uma senha digite "000000" para cadastrar uma nova.',1  )
		 //Return( .F. )
	     _lRet	:= .F.
	     Break
	  EndIf
   EndIf

   If Len(AllTrim(_cMatric))==6
	  SRA->( DBSetOrder(1) )
	  If SRA->( DBSeek( AllTrim( xFilial('SRA') + AllTrim( _cMatric ) ) ) ) .And. Empty( SRA->RA_DEMISSA ) .And. SRA->RA_SITFOLH <> 'D'
		 _cmat2      := SRA->RA_MAT
		 _lRet		:= .T.
	  EndIf
   Else
	  SRA->( DBSetOrder(5) )
	  If SRA->( DBSeek( xFilial('SRA') + _cMatric ) )
		 While SRA->( !Eof() ) .And. SRA->( RA_FILIAL + RA_CIC ) == xFilial('SRA') + _cMatric 
			If Empty( SRA->RA_DEMISSA ) .And. SRA->RA_SITFOLH <> 'D'
		       _lRet		:= .T.
			   _cmat2 := SRA->ra_MAT
				Exit
			EndIf
		    SRA->( DBSkip() )
		 EndDo
	  EndIf
   EndIf

   If !_lRet
	  U_ITMsg( 'Funcionário não encontrado na Filial "'+ xFilial('SRA') +'" com os dados de Matrícula ou CPF informado. ','Atenção'	,;
	   								'Favor entrar em contato com o RH.' , 1  )
      Break
   EndIf
	
   If _lRet
	  //====================================================================================================
	  // Bloquear a compra de produtos por funcionários afastados
	  //====================================================================================================
	  SR8->(DBSetOrder(1))  // R8_FILIAL+R8_MAT+DToS(R8_DATAINI)+R8_TIPO
	  SR8->(DBSeek(xFilial("SR8")+SRA->RA_MAT))
	  While ! SR8->(Eof()) .And. SR8->(R8_FILIAL+R8_MAT) == xFilial("SR8")+SRA->RA_MAT
		 If SR8->R8_DPAGOS # 0
		    SR8->(DBSkip())
		    Loop		
		 EndIf
		
		 If SR8->R8_TIPOAFA == "006" 
		    Exit
		 Else	
		    If SR8->R8_TIPOAFA == "001"
			   If _ddtoper >= (SR8->R8_DATAINI-15) .And. _ddtoper <= SR8->R8_DATAFIM//) .Or. (_ddtoper >= SR8->R8_DATAINI .
	              U_ITMsg( 'Não é possivel realizar compras no periodo de ferias ou 15 dias antes das ferias programadas','Atenção',;
						   'Perido que não pode fazer compras: '+DToC((SR8->R8_DATAINI-15)) + " ate "+DToC(SR8->R8_DATAFIM) , 1  )
			      _lRet := .F.
				  Exit
		       EndIf
            Else
			   If (Empty(SR8->R8_DATAFIM) .Or. _ddtoper <= SR8->R8_DATAFIM)
			      If Empty(SR8->R8_DATAFIM)
			         _cMsg:='Perido que não pode fazer compras: desde de '+DToC((SR8->R8_DATAINI)) 
			      Else
			         _cMsg:='Perido que não pode fazer compras: '+DToC((SR8->R8_DATAINI)) + " ate "+DToC(SR8->R8_DATAFIM)
			      EndIf
	              U_ITMsg( 'Não é possivel realizar compras no momento','Atenção',_cMsg, 1  )
			      _lRet := .F.
				  Exit
		       EndIf
			EndIf
		 EndIf 
          
		 SR8->(DBSkip())
	  EndDo   		
      If !_lRet
	     Break
      EndIf
   EndIf

   If _lRet
	  _lRet := .F.
	
	  If _lAtivPas .And. Empty( SRA->RA_I_SENHA )
	     _cSenha	:= ''
		 _oFont	:= TFont():New( "Arial" ,, 14 ,, .F. ,,,, .T. , .F. )
		
		 DEFINE DIALOG _oDlgPas FROM 0,0 TO 193,500 PIXEL
		
		     TGroup():New( 002 , 002 , 016 , 040 , 'Matrícula: '			, _oDlgPas ,, CLR_GRAY , .T. )
			 TGroup():New( 002 , 045 , 016 , 105 , 'CPF: '				, _oDlgPas ,, CLR_GRAY , .T. )
			 TGroup():New( 020 , 002 , 034 , 250 , 'Funcionário: '		, _oDlgPas ,, CLR_GRAY , .T. )
			 TGroup():New( 038 , 002 , 080 , 250 , 'Cadastrar senha: '	, _oDlgPas ,, CLR_GRAY , .T. )
			
			 TSay():New( 008 , 008 , {|| SRA->RA_MAT		} , _oDlgPas ,, _oFont ,,,, .T. ,,, 030 , 10 )
			 TSay():New( 008 , 050 , {|| SRA->RA_CIC		} , _oDlgPas ,, _oFont ,,,, .T. ,,, 050 , 10 )
		     TSay():New( 026 , 005 , {|| SRA->RA_NOME	} , _oDlgPas ,, _oFont ,,,, .T. ,,, 200 , 10 )
		    
		     TSay():New( 050 , 010 , {|| 'Nova Senha: '	} , _oDlgPas ,, _oFont ,,,, .T. ,,, 200 , 10 )
		     TSay():New( 065 , 010 , {|| 'Confirmar: '	} , _oDlgPas ,, _oFont ,,,, .T. ,,, 200 , 10 )
		    
		     TSay():New( 050 , 100 , {|| '*As senhas devem ser cadastradas com 6 dígitos!' } , _oDlgPas ,, _oFont ,,,, .T. ,,, 200 , 10 )
		    
			 TGet():New( 048 , 050                            , {|u| If( PCount() > 0 , _cGet1 := u , _cGet1 ) }       , _oDlgPas , 040 , 010 , "@K*" ,, _nClrText ,_nClrBack,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .T. ,, "_cGet1" ,,,, )
			 TGet():New( 063 , 050                            , {|u| If( PCount() > 0 , _cGet2 := u , _cGet2 ) }       , _oDlgPas , 040 , 010 , "@K*" ,, _nClrText ,_nClrBack,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .T. ,, "_cGet2" ,,,, )
//			 TGet():New( 50  , ( _aPosAux[01][04] / 2 ) - 050 , {|u| If( PCount() > 0 , _cSenha := u , _cSenha ) }		, _oPanel , 096 , 009 , "@K*" ,, _nClrText ,_nClrBack,, .F. ,, .T. ,, .F. , {|| _lAtivPas } , .F. , .F. ,, .F. , .T. ,, _cSenha ,,,, )
		
		      @ 082,149 BUTTON _oBtn1 PROMPT "Confirmar"	ACTION ( IIf( _cGet1 == _cGet2 .And. Len( AllTrim( _cGet1 ) ) == 6 , ( _cSenha := _cGet1 , _oDlgPas:End() ) , U_ITMsg('As senhas digitadas não conferem ou não são válidas!','Atenção!',,1) ) ) SIZE 050,012 OF _oDlgPas PIXEL
		      @ 082,200 BUTTON _oBtn2 PROMPT "Cancelar"	ACTION ( _oDlgPas:End() ) SIZE 050,012 OF _oDlgPas PIXEL
		
		 ACTIVATE DIALOG _oDlgPas CENTERED
		
		 If !Empty(_cSenha) .And. Len( _cSenha ) == 6
			RecLock('SRA',.F.)
			SRA->RA_I_SENHA := Embaralha( _cSenha , 0 )
			SRA->( MSUnLock() )
		 EndIf
		
		 _cSenha := Space( 6 )
		
      ElseIf Embaralha( SRA->RA_I_SENHA , 1 ) == _cSenha .Or. ( !_lAtivPas .And. Empty(_cSenha) )
	
		 If SRA->RA_FILIAL <> xFilial('SRA')
			
			U_ITMsg( 'O funcionário da matrícula atual não está cadastrado na Filial '+ xFilial('SRA'),'Atenção','Verifique os dados digitados!' ,1 )
			
		 ElseIf Empty( SRA->RA_DEMISSA ) .And. SRA->RA_SITFOLH <> 'D'
		
			SA1->( DBSetOrder(3) )
			If SA1->( DBSeek( xFilial('SA1') + SubStr( SRA->RA_CIC + Space( TamSX3('A1_CGC')[01] ) , 1 , TamSX3('A1_CGC')[01] ) ) )
				
				If SA1->A1_MSBLQL == '1'
					
					U_ITMsg( 'O funcionário da matrícula atual está com o cadastrado de "Cliente" bloqueado no sistema',;
												'Atenção','Verifique os dados digitados e o cadastro do funcionário!' , 1 )
					
				Else
					
					If Empty( SA1->A1_LC ) .Or. SA1->A1_LC <= 0
						
						U_ITMsg( 'O funcionário da matrícula atual está com o cadastrado de "Cliente" sem limite de crédito para compras',;
						 			'Atenção','Verifique os dados digitados e o cadastro do funcionário!' , 1 )
						
					Else
					    
					    If U_ITMsg( 'Funcionário: '+ Capital( AllTrim( SRA->RA_NOME ) ) , 'Confirmação de Identificação',,3,2,2 )
							_nLimite	:= SA1->A1_LC
							_lRet		:= .T.
						EndIf
						
					EndIf
					
				EndIf
			
			Else
			
				U_ITMsg( 'O funcionário da matrícula atual não está cadastrado como "Cliente" no sistema',;
				 		'Atenção','Verifique os dados digitados e o cadastro do funcionário!' , 1 )
			
			EndIf
			
		Else
		
			U_ITMsg( 'O funcionário atual não está ativo no sistema!','Atenção','Verifique a situação com o Depto. de RH !' ,1 )
		
		EndIf
	
	 Else
	
		U_ITMsg( 'Usuário e senha inválidos!' , 'Atenção!' ,,1 )
		
	 EndIf
	
   EndIf

   If _lRet
	
	  _aDados := {}
	
	  _cQuery := " SELECT Z12.R_E_C_N_O_ AS REGZ12 "
	  _cQuery += " FROM  "+ RETSQLNAME('Z12') +" Z12 "
	  _cQuery += " WHERE "+ RETSQLCOND('Z12')
	  _cQuery += " AND Z12.Z12_MATRIC = '"+ SRA->RA_MAT +"' "
	  _cQuery += " AND Z12.Z12_STATUS IN ('I','E') "
	
	  // Só traz para ajuste se For pedido incluido dentro mês ou dentro de período de 5 dias
	  If _nchars == 6 //Procura padrão por pedido dentro do mês se parâmetro IT_PCFUNC igual à N
	     //_cQuery += " AND SubStr( Z12.Z12_DATA , 1 , " + AllTrim(Str(_nchars)) + " ) = '"+ SubStr( DToS( _ddtoper ) , 1 , _nchars ) +"' " 
	     _cQuery += " AND (Z12.Z12_STATUS = 'E' AND (SubStr( Z12.Z12_DATA , 1 , " + AllTrim(Str(_nchars)) + " ) = '"+ SubStr( DToS( _ddtoper ) , 1 , _nchars ) +"' ) OR (Z12.Z12_STATUS = 'I')) " 
	  Else  //Procura por pedido até 5 dias próximo se IT_PCFUNC igual à S
	     //_cQuery += " AND Z12.Z12_DATA >= '" +   DToS( _ddtoper - 5 ) +"' AND Z12.Z12_DATA <= '" +   DToS( _ddtoper + 5 ) +"'" 
	     _cQuery += " AND (Z12.Z12_STATUS = 'E' AND (Z12.Z12_DATA >= '" +   DToS( _ddtoper - 5 ) +"' AND Z12.Z12_DATA <= '" +   DToS( _ddtoper + 5 ) +"' ) OR (Z12.Z12_STATUS = 'I')) " 
	  EndIf
	
	  MPSysOpenQuery( _cQuery , _cAlias)
	
	  (_cAlias)->( DBGoTop() )
	  If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->REGZ12 )
		
		 Z12->( DBGoTo( (_cAlias)->REGZ12 ) )
		
		 _cLocEnt := Z12->Z12_LOCENT 
		
		If Z12->Z12_STATUS == 'E'
		   If _nchars == 6
			  U_ITMsg('Já existe uma solicitação de hoje efetivada no período ['+ MesExtenso(_ddtoper)+'/'+ cValToChar(Year(_ddtoper));
				 		+'] para o funcionário atual e não poderá mais ser alterado! '	,'Atenção',;
						'Caso necessário entre em contato com a área Logística.'+ CRLF +'Solicitação: '+ Z12->Z12_CODIGO	, 1 )
		   Else
			  U_ITMsg(	'Já existe uma solicitação efetivada no dia ['+ MesExtenso(_ddtoper)+'/'+ cValToChar(Year(_ddtoper));
				 			+'] para o funcionário atual e não poderá mais ser alterado! '	, 'Atenção',;
						'Caso necessário entre em contato com a área Logística.'+ CRLF +'Solicitação: '+ Z12->Z12_CODIGO	 , 1 )
		   EndIf
			
		   _lRet := .F.
			
		ElseIf Z12->Z12_STATUS == 'I'
			
			Z13->( DBSetOrder(1) )
			If Z13->( DBSeek( xFilial('Z13') + Z12->Z12_CODIGO ) )
			   While Z13->( !Eof() ) .And. Z13->( Z13_FILIAL + Z13_CODPED ) == xFilial('Z13') + Z12->Z12_CODIGO
		          aAdd( _aDados , { Z13->Z13_CODPRD , Z13->Z13_QTD } )
				  
				  Z13->( DBSkip() )
			   EndDo
			EndIf
		 EndIf
	  EndIf
	
	  (_cAlias)->( DBCloseArea() )
   EndIf

   If !_lRet
	  _cMatric := Space(11)
   Else
	  _cMatric := _cmat2 //Se validou a matricula garante que a variável de identificação fica igual a matricula
   EndIf

End Sequence

Return( _lRet )


/*
===============================================================================================================================
Programa--------: AOMS070P02
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para montar a página de identificação dos funcionários
===============================================================================================================================
Parametros------: 	_oPanel - objeto da janela de execução
					_aPosAux - array de posições da tela
					_oBrowse - objeto do browse de produtos
					_aDados - array com dados de pedido preexistente
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070P02( _oPanel , _aPosAux , _oBrowse , _aDados )

Local _aPosPan	:= FWGetDialogSize( _oPanel )
Local _aPrdAux	:= {}
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nPosScan	:= 0
Local _nQtdIni	:= 0
Local _nVrIPI  := 0

Local _nClrText := Nil 
Local _nClrBack := Nil
Local _cTheme   := Nil 

_cTheme := totvs.framework.css.getNewWebAppTheme()
If !Empty(_cTheme) .And. _cTheme == "DARK"
	_nClrText := CLR_WHITE
	_nClrBack := CLR_BLACK
Else
	_nClrText := CLR_BLACK
	_nClrBack := CLR_WHITE
EndIf

_nPedido	:= 0
_aPrdAux	:= {}

_cQuery := " SELECT "
_cQuery += "     Z11.Z11_CODPRD ,"
_cQuery += "     Z11.Z11_VALOR,   "
_cQuery += "     SBZ.BZ_IPI "
_cQuery += " FROM  "+ RetSqlName('Z11') +" Z11 "
_cQuery += " LEFT JOIN  "+ RetSqlName('SBZ') +" SBZ ON BZ_FILIAL = '"+ xFilial('SE1') +"' AND Z11_CODPRD = BZ_COD AND SBZ.D_E_L_E_T_ = ' '"
_cQuery += " WHERE "+ RetSqlCond('Z11')
_cQuery += " AND Z11_FILTAB LIKE '%"+ xFilial('SE1') +"%' "
_cQuery += " AND Z11_STATUS = 'S' "
_cQuery += " AND Z11_DATINI <= '"+ DToS( _ddtoper ) +"' "
_cQuery += " AND Z11_DATFIM >= '"+ DToS( _ddtoper ) +"' "
_cQuery += " ORDER BY Z11.Z11_CODPRD "

MPSysOpenQuery( _cQuery , _cAlias)

(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
	
	_nQtdIni := 0
	
	If ( _nPosScan := aScan( _aDados , {|X| X[1] == (_cAlias)->Z11_CODPRD } ) ) > 0
		_nQtdIni := _aDados[_nPosScan][02]
	EndIf

   _nVrIPI := Round(Noround((_cAlias)->BZ_IPI/100*((_cAlias)->Z11_VALOR*_nQtdIni),3),2)

	aAdd( _aPrdAux , {	(_cAlias)->Z11_CODPRD,;
                        Posicione( 'SB1' , 1 , xFilial('SB1') + (_cAlias)->Z11_CODPRD , 'B1_DESC' ),;
                        SB1->B1_UM,;
                        (_cAlias)->Z11_VALOR,;
                        _nQtdIni,;
                  		(_cAlias)->BZ_IPI ,;
                        _nVrIPI ,;
                        ((_cAlias)->Z11_VALOR * _nQtdIni ) + _nVrIPI })
	
	_nPedido += ( ((_cAlias)->Z11_VALOR * _nQtdIni) +_nVrIPI  )
	
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

_nSaldo	:= _nLimite - _nPedido

_oSayL	:= TSay():New( _aPosPan[01] + 005 , 005 , {|| 'Limite disponível: '											} , _oPanel ,,,,,, .T. ,,, 200 , 20 )
_oTGetL	:= TSay():New( _aPosPan[01] + 005 , 050 , {|| AllTrim( Transform( _nLimite , '@E 999,999,999,999.99' ) )	} , _oPanel ,,,,,, .T. ,,, 200 , 20 )

_oSayP	:= TSay():New( _aPosPan[01] + 005 , 200 , {|| 'Total do Pedido: '											} , _oPanel ,,,,,, .T. ,,, 200 , 20 )
_oTGetP	:= TSay():New( _aPosPan[01] + 005 , 250 , {|| AllTrim( Transform( _nPedido , '@E 999,999,999,999.99' ) )	} , _oPanel ,,,,,, .T. ,,, 200 , 20 )

_oSayS	:= TSay():New( _aPosPan[01] + 005 , 300 , {|| 'Saldo do Pedido: '											} , _oPanel ,,,,,, .T. ,,, 200 , 20 )
_oTGetS	:= TSay():New( _aPosPan[01] + 005 , 350 , {|| AllTrim( Transform( _nSaldo , '@E 999,999,999,999.99' ) )		} , _oPanel ,,,,,, .T. ,,, 200 , 20 )

_oSayR	 := TSay():New( _aPosPan[01] + 025    ,005 , {|| 'Local de Retirada: '										} , _oPanel ,,,,,, .T. ,,, 200 , 20 )
_oLocRet := TComboBox():New(_aPosPan[01] + 025,050 , {|u|If(PCount()>0,_cLocEnt :=u,_cLocEnt)         }, _aLocEnt,60,20,_oPanel  ,,,,,,.T.,,,,,,,,,'_cLocEnt')

          //TCBrowse():New( [ nRow ]               , [ nCol ]         , [ nWidth ]             , [ nHeight ]                                   , [ bLine ], [ aHeaders ]                                                                      , [ aColSizes ]             , [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ], [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
_oBrowse := TCBrowse():New( _aPosAux[01][01] + 015 , _aPosAux[01][02] , _aPosAux[01][04] - 005 , _aPosAux[01][03] - _oPanel:OPARENT:NTOP - 030 ,          , {'Produto','Descrição','1ª UM','Valor','2ª UM','Qtd. 1ª UM','Qtd. 2ª UM','Total'} , {50,50,50,50,50,50,50,50} , _oPanel ,           ,            ,            ,            ,{||}           ,            ,          ,            , _nClrText   , _nClrBack    ,,.F.,,.T.,,.F.,,, )
           
_oBrowse:SetArray( _aPrdAux )

_oBrowse:AddColumn( TCColumn():New( 'Produto'      , {|| _aPrdAux[_oBrowse:nAt][01] } ,						    ,,, "LEFT"  ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( 'Descrição'    , {|| _aPrdAux[_oBrowse:nAt][02] } ,						    ,,, "LEFT"  ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( '1ª UM'        , {|| _aPrdAux[_oBrowse:nAt][03] } ,						    ,,, "LEFT"  ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( 'Valor'        , {|| _aPrdAux[_oBrowse:nAt][04] } ,'@E 999,999,999,999.99'	,,, "RIGHT" ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( 'Quantidade'   , {|| _aPrdAux[_oBrowse:nAt][05] } ,'@E 999,999,999.999'	    ,,, "RIGHT" ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( '% IPI'        , {|| _aPrdAux[_oBrowse:nAt][06] } ,'@E 999.999'	            ,,, "RIGHT" ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( 'Vr IPI'       , {|| _aPrdAux[_oBrowse:nAt][07] } ,'@E 999,999,999,999.99'	,,, "RIGHT" ,, .F. , .T. ,,,, .F. ) )
_oBrowse:AddColumn( TCColumn():New( 'Total'        , {|| _aPrdAux[_oBrowse:nAt][08] } ,'@E 999,999,999,999.99'	,,, "RIGHT" ,, .F. , .T. ,,,, .F. ) )

_oBrowse:bLDblClick		:= {|z,x| IIf( x == 05 , ( lEditCell( _aPrdAux , _oBrowse , "@E 999,999,999.999" , x ) , AOMS070VDQ( x , @_oBrowse ) ) , .F. ) , _oBrowse:Refresh() }
_oBrowse:lAdjustColSize	:= .F.

Return

/*
===============================================================================================================================
Programa--------: AOMS070VP2
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para validar a montagem de pedido do funcionário
===============================================================================================================================
Parametros------: _oBrowse - objeto do browse de produtos
				  _aDados - array de carregamento dos dados do pedido
===============================================================================================================================
Retorno---------: lret - lógico se grava ou não pedido
===============================================================================================================================
*/

Static Function AOMS070VP2( _oBrowse , _aDados )

Local _lRet 	:= .T. As Logic
Local _nI		:= 0 As Numeric
Local _nQtdSeg	:= 0 As Numeric

Begin Sequence

   _aDados	:= {}

   If _nSaldo < 0
	
	  U_ITMsg( 'O pedido digitado superou o limite de crédito do funcionário para compras!','Atenção','Verifique os dados digitados e tente novamente.' , 1 )
	  _lRet := .F.

   Else
	
	  If _nPedido == 0
		 U_ITMsg( 'Não é possível incluir um pedido vazio!','Atenção',' Verifique os dados digitados e tente novamente.' ,1 )
		 _lRet := .F.
	  Else
		 For _nI := 1 To Len( _oBrowse:aArray )
			 If _oBrowse:aArray[_nI][05] > 0
				DBSelectArea('SB1')
				SB1->( DBSetOrder(1) )
				SB1->( DBSeek( xFilial('SB1') + _oBrowse:aArray[_nI][01] ) )
				
				If SB1->B1_TIPCONV == "D"
					_nQtdSeg := _oBrowse:aArray[_nI][05] / SB1->B1_CONV
				Else
					_nQtdSeg := _oBrowse:aArray[_nI][05] * SB1->B1_CONV 
				EndIf

            aAdd( _aDados , { _oBrowse:aArray[_nI][01],;
                              _oBrowse:aArray[_nI][02],;
                              _oBrowse:aArray[_nI][03],;
                              _oBrowse:aArray[_nI][04],;
                              _oBrowse:aArray[_nI][03],;
                              _oBrowse:aArray[_nI][05],;
                              SB1->B1_SEGUM,;
                              _nQtdSeg,;
                              _oBrowse:aArray[_nI][06],;
                              _oBrowse:aArray[_nI][07],;
                              _oBrowse:aArray[_nI][08]})
				
		     EndIf
			
		 Next _nI
		
	  EndIf

   EndIf

   AOMS070P03( _oStepWiz:AWIZSTRU[3]:OUSERPANEL , _aPosAux , _aDados )

   If _lRet
      _oLocRet:Setfocus()
   EndIf

End Sequence

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS070P03
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para montar a página de confirmação do pedido
===============================================================================================================================
Parametros------: 	_oPanel - objeto da janela de execução
					_aPosAux - array com posições da tela
					_aDados - array com dados de pedido preexistente
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070P03( _oPanel , _aPosAux , _aDados )

Local _cHtml	:= ''
Local _nI		:= 0

If Empty(_oPanel)
	Return
EndIf

DBSelectArea('SRA')
SRA->( DBSetOrder(1) )
SRA->( DBSeek( xFilial('SRA') + _cMatric ) )

DBSelectArea('SA1')
SA1->( DBSetOrder(3) )
SA1->( DBSeek( xFilial('SA1') + SubStr( SRA->RA_CIC + Space( TamSX3('A1_CGC')[01] ) , 1 , TamSX3('A1_CGC')[01] ) ) )

_cHtml := "<html>"
_cHtml += "<header><title>Resumo Pedido</title></header>"
_cHtml += "<body>"
_cHtml += '<table>'
_cHtml += '<tr><td>Funcionário: </td><td>'+ AllTrim(SRA->RA_NOME) +' | CPF: '+ AllTrim(SRA->RA_CIC) +' | Filial: '+ AllTrim(SRA->RA_FILIAL) +' | Matrícula: '+ AllTrim( SRA->RA_MAT ) +'</td></tr>'
_cHtml += '<tr><td>Cliente: </td><td>'+ SA1->A1_COD +'/'+ SA1->A1_LOJA +' - '+ AllTrim(SA1->A1_NOME) +' </td></tr>'
_cHtml += '<tr><td>Endereço: </td><td>'+ AllTrim(SA1->A1_END) +' '+ AllTrim(SA1->A1_COMPLEM) +' - '+ AllTrim(SA1->A1_BAIRRO) +' - '+ AllTrim(SA1->A1_MUN) +'/'+ AllTrim(SA1->A1_EST) +'</td></tr>'
_cHtml += '<tr><td>Local de Entrega: </td><td>'+ AllTrim(Upper(U_ITRetBox( _cLocEnt ,"Z12_LOCENT"))) +'</td></tr>'
_cHtml += '</table>'
_cHtml += '<br>'
_cHtml += '<table>'
_cHtml += '<tr><td colspan="30"><hr></td></tr>'
_cHtml += '<tr>'
_cHtml += '<td><center>Produtos</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>Un. Medida</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>Valor Unit.</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>1ª UM Solic.</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>Qtd. 1ª UM</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>2ª UM</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>Qtd. 2ª UM</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>% IPI</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>Valor IPI</center></td>'
_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
_cHtml += '<td><center>Valor Total</center></td>'
_cHtml += '</tr>'
_cHtml += '<tr><td colspan="30"><hr></td></tr>'

For _nI := 1 To Len( _aDados )
	
	_cHtml += '<tr>'
	_cHtml += '<td align="Left"   >'+ _aDados[_nI][01] +' - '+ _aDados[_nI][02] +'</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ _aDados[_nI][03] +'</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Right"  >'+ Transform( _aDados[_nI][04] , "@E 999,999,999,999.99" ) +'&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ _aDados[_nI][05] +'</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ Transform( _aDados[_nI][06] , "@E 999,999,999,999.999" ) +'</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ _aDados[_nI][07] +'</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ Transform( _aDados[_nI][8] , "@E 999,999,999,999.99" ) +'</td>'
   _cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ Transform( _aDados[_nI][9] , "@E 999.99" ) +'</td>'
   _cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Center" >'+ Transform( _aDados[_nI][10] , "@E 999,999,999,999.99" ) +'</td>'
	_cHtml += '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>'
	_cHtml += '<td align="Right" >'+ Transform( _aDados[_nI][11] , "@E 999,999,999,999.99" ) +'</td>'
	_cHtml += '</tr>'
	
Next _nI

_cHtml += '<tr><td colspan="30"><hr></td></tr>'
_cHtml += '<tr>'
_cHtml += '<td colspan="18">Total da Solicitação</td>'
_cHtml += '<td align="Right" >'+ Transform( _nPedido , "@E 999,999,999,999.99" ) +'</td>'
_cHtml += '</tr>'
_cHtml += "</table>"
_cHtml += "</body>"
_cHtml += "</html>"

_oFont	:= TFont():New( 'Courier new' ,, -9 , .F. )
_oScrAux	:= TScrollBox():New( _oPanel , 01 , 01 , _aPosAux[01][03] - _oPanel:OPARENT:NTOP + 020 , _aPosAux[01][04] , .T. , .T. , .F. )
_oPanAux	:= TPanel():New( 0 , 0 , '' , _oScrAux , _oFont , .F. ,,,, 570 , 062 + ( _nI * 7.5 ) , .F. , .F. )

_oPanAux:cCaption := _cHtml

Return

/*
===============================================================================================================================
Programa--------: AOMS070VDQ
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para validar a digitação de quantidades dos pedidos
===============================================================================================================================
Parametros------: 	_nOpc - não utilizado
					_oBrowse - objeto do browse de produtos
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070VDQ( _nOpc , _oBrowse )

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .T.
Local _nTotPed	:= 0
Local _nConv	:= 0
Local _nI		:= 0
Local _cCodTPONFRAC := U_ITGETMV( "IT_VOLN3M","00060034701") As Char // QUEIJO RALADO 40 G
Local _cTheme
Local _nClrText
Local _nClrBack

_cTheme := totvs.framework.css.getNewWebAppTheme()
If !Empty(_cTheme) .And. _cTheme == "DARK"
	_nClrText := CLR_WHITE
	_nClrBack := CLR_BLACK
Else
	_nClrText := CLR_BLACK
	_nClrBack := CLR_WHITE
EndIf

_cQuery := " SELECT "
_cQuery += "     Z11.Z11_UMSOLI AS CODVLD "
_cQuery += " FROM  "+ RetSqlName('Z11') +" Z11 "
_cQuery += " WHERE "+ RetSqlCond('Z11')
_cQuery += " AND Z11.Z11_FILTAB LIKE '%"+ xFilial('SE1') +"%' "
_cQuery += " AND Z11.Z11_CODPRD = '"+ _oBrowse:aArray[_oBrowse:nAt][01] +"' "
_cQuery += " AND Z11.Z11_DATINI <= '"+ DToS( _ddtoper ) +"' "
_cQuery += " AND Z11.Z11_DATFIM >= '"+ DToS( _ddtoper ) +"' "
_cQuery += " AND Z11.Z11_STATUS = 'S' "

MPSysOpenQuery( _cQuery , _cAlias)

(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->CODVLD )

	If (_cAlias)->CODVLD == '2'
		
		_nConv := Posicione('SB1',1,xFilial('SB1')+_oBrowse:aArray[_oBrowse:nAt][01],'B1_CONV')
		
		If AllTrim(_oBrowse:aArray[_oBrowse:nAt][01]) $  _cCodTPONFRAC
		   _nConv := Posicione('SB1',1,xFilial('SB1')+_oBrowse:aArray[_oBrowse:nAt][01],'B1_I_QT3UM')
		EndIf
		
		If _nConv == 0
			_nConv := Posicione('SB1',1,xFilial('SB1')+_oBrowse:aArray[_oBrowse:nAt][01],'B1_I_FATCO')
		EndIf
		
		If Mod( _oBrowse:aArray[_oBrowse:nAt][05] , _nConv ) > 0
		
			U_ITMsg(	'Para o produto: '+ AllTrim( SB1->B1_DESC ) +' devem ser solicitadas as quantidades em múltiplos de: ';
						+ cValtoChar( _nConv ) +'! '+ CRLF +	'[Ex. '+ cValtoChar( _nConv ) +' - '+ cValtoChar( _nConv * 2 );
						 +' - '+ cValtoChar( _nConv * 3 ) +' ]' , 'Atenção!' , ,1 )
			
			_oBrowse:aArray[_oBrowse:nAt][05] := 0
			
		EndIf
		
	EndIf
	
   _oBrowse:aArray[_oBrowse:nAt][08] := 0
   _oBrowse:aArray[_oBrowse:nAt][07] := Round(Noround(_oBrowse:aArray[_oBrowse:nAt][06] / 100 * (_oBrowse:aArray[_oBrowse:nAt][04] * _oBrowse:aArray[_oBrowse:nAt][05]),3),2)
   _oBrowse:aArray[_oBrowse:nAt][08] := (_oBrowse:aArray[_oBrowse:nAt][04] * _oBrowse:aArray[_oBrowse:nAt][05])  + _oBrowse:aArray[_oBrowse:nAt][07]  
	
	For _nI := 1 To Len( _oBrowse:aArray )
		
		_nTotPed += _oBrowse:aArray[_nI][08]
		
	Next _nI
	
	_nPedido := _nTotPed
	_nSaldo  := ( _nLimite - _nPedido )
	
	_oTGetL:SetText( AllTrim( Transform( _nLimite	, '@E 999,999,999,999.99' ) ) )
	_oTGetP:SetText( AllTrim( Transform( _nPedido	, '@E 999,999,999,999.99' ) ) )
	_oTGetS:SetText( AllTrim( Transform( _nSaldo	, '@E 999,999,999,999.99' ) ) )
	
	If _nSaldo < 0
		_oSayS:nClrText		:= CLR_RED
		_oTGetS:nClrText	:= CLR_RED
	Else
		_oSayS:nClrText		:= _nClrText //CLR_BLACK 
		_oTGetS:nClrText	:= _nClrText //CLR_BLACK 
	EndIf

Else

	U_ITMsg( 'Falha ao identificar o produto na tabela de preços!','Atenção',;
			' Execute a rotina de solicitação novamente para atualizar a tabela, caso o erro persista informe o departamento responsável.' , 1 )

EndIf

(_cAlias)->( DBCloseArea() )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS070GRV
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para validar a digitação de quantidades dos pedidos
===============================================================================================================================
Parametros------: _aDados - array com dados do pedido
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070GRV( _aDados )

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nQtdPed	:= 0
Local _nI		:= 0
Local _cCodZ12	:= ''
Local _cFilLocEnt := U_ITGETMV( 'IT_FILLOCEN' , "92;" )

Begin Sequence
   If xFilial("SRA") $ _cFilLocEnt // Empty(_cLocEnt) 
      While .T.
         U_AOMS070l()
		 If ! Empty(_cLocEnt)
		    Exit
	     EndIf
      EndDo
   ElseIf Empty(_cLocEnt) 
      _cLocEnt := "O"
   EndIf
   
   _cQuery := " SELECT Z12.R_E_C_N_O_ AS REGZ12 "
   _cQuery += " FROM  "+ RETSQLNAME('Z12') +" Z12 "
   _cQuery += " WHERE "+ RETSQLCOND('Z12')
   _cQuery += " AND Z12.Z12_MATRIC = '"+ _cMatric +"' "
   _cQuery += " AND Z12.Z12_STATUS = 'I' "
   //_cQuery += " AND SubStr( Z12.Z12_DATA , 1 , " + AllTrim(Str(_nchars)) + " )   = '"+ SubStr( DToS( _ddtoper ) , 1 , _nchars ) +"' "

   MPSysOpenQuery( _cQuery , _cAlias)
   
   Begin Transaction 

   (_cAlias)->( DBGoTop() )
   If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->REGZ12 )
	
	  Z12->( DBGoTo( (_cAlias)->REGZ12 ) )
	
	  RecLock( 'Z12' , .F. )
	
   Else
	  _cCodZ12 := AOMS070NEW()
	
	  RecLock( 'Z12' , .T. )
	
	  Z12->Z12_FILIAL		:= xFilial( 'Z12' )
	  Z12->Z12_CODIGO		:= AOMS070NEW()
 	  Z12->Z12_MATRIC		:= _cMatric
	
   EndIf

   (_cAlias)->( DBCloseArea() )

   Z12->Z12_DATA		:= _ddtoper
   Z12->Z12_HORA		:= Time()
   Z12->Z12_VALOR		:= _nPedido
   Z12->Z12_STATUS		:= 'I'
   Z12->Z12_LOCENT     := _cLocEnt  

   Z12->( MSUnLock() )

   //====================================================================================================
   // Zera os itens da solicitação para poder gravar novamente
   //====================================================================================================
   // A exclusão física de registros da tabela Z13 foi substituida pela exclusão lógica.
   //====================================================================================================
   Z13->(DBSetOrder(1)) // Z13_FILIAL+Z13_CODPED+Z13_ITEM 
   Z13->(DBSeek(Z12->Z12_FILIAL + Z12->Z12_CODIGO))
   While ! Z13->(Eof()) .And. Z13->(Z13_FILIAL+Z13_CODPED) == Z12->Z12_FILIAL + Z12->Z12_CODIGO 
      Z13->(RecLock("Z13",.F.))
      Z13->(DbDelete())
      Z13->(MSUnLock())
   
      Z13->(DBSkip())
   EndDo

   //====================================================================================================
   // A exclusão física de registros da tabela Z13 foi substituida pela exclusão lógica.
   //==================================================================================================== 
   /*
   _cQuery := " DELETE "   // Alterar esta linha para utilizar RecLock() 
   _cQuery += " FROM   "+ RETSQLNAME('Z13') +" Z13 "
   _cQuery += " WHERE  "+ RETSQLCOND('Z13')
   _cQuery	+= " AND Z13.Z13_CODPED = '"+ Z12->Z12_CODIGO +"' "

   If ( TcSqlExec( _cQuery ) < 0 )
	
	  U_ITMsg( 'Ocorreu um erro durante a gravação da solicitação! Informe a equipe de TI/Sistemas.' , 'Atenção!' , 1 )
	  Alert( TCSQLError() )
	  DisarmTransaction()
	  Return
   EndIf
   */

   For _nI := 1 To Len( _aDados )

      _nQtdPed := 0

      If _aDados[_nI][03] == _aDados[_nI][05]
         _nQtdPed := _aDados[_nI][06]
      Else
         DBSelectArea('SB1')
         SB1->( DBSetOrder(1) )
         If SB1->( DBSeek( xFilial('SB1') + _aDados[_nI][01] ) )
            If SB1->B1_TIPCONV == 'D'
               _nQtdPed := _aDados[_nI][06] * SB1->B1_CONV
            Else
               _nQtdPed := _aDados[_nI][06] / SB1->B1_CONV
            EndIf
         Else
            _nQtdPed := 0
         EndIf 
      EndIf

      If _nQtdPed > 0

         RecLock( 'Z13' , .T. )

         Z13->Z13_FILIAL   := xFilial('Z13')
         Z13->Z13_CODPED   := Z12->Z12_CODIGO
         Z13->Z13_ITEM     := StrZero( _nI , 3 )
         Z13->Z13_CODPRD   := _aDados[_nI][01]
         Z13->Z13_QTD      := _nQtdPed
         Z13->Z13_VUNIT    := _aDados[_nI][04]
         Z13->Z13_PIPI     := _aDados[_nI][09]
         Z13->Z13_VRIPI    := _aDados[_nI][10]

         Z13->( MSUnLock() )

      EndIf

   Next _nI

   End Transaction 

   MSUnLockAll()

   If U_ITMsg( 'Solicitação ['+ Z12->Z12_CODIGO +'] gravada com sucesso! Deseja imprimir?' , "Processo concluído",,3,2,2)
	
	  U_ROMS011()
	
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: AOMS070E
Autor-----------: Alexandre Villar
Data da Criacao-: 31/08/2015
===============================================================================================================================
Descrição-------: Rotina para efetivação das solicitações de compras dos funcionários
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS070E()

Local _xAcesso		:= U_ITACSUSR( 'ZZL_ADMPFU' , 'S' )

Private _oBrwEfe	:= FWMBrowse():New()
Private _ddtoper	:= Date()

//====================================================================================================
// Validação do acesso do usuário
//====================================================================================================
If ValType( _xAcesso ) == 'N' .And. _xAcesso == 0

	U_ITMsg( 'Usuário não está cadastrado na Gestão de Usuários do Configurador Italac!' ,'Atenção',,1 )
	Return

ElseIf !_xAcesso
	
	U_ITMsg( 'Usuário sem acesso à rotina de efetivação dos pedidos de funcionários!' , 'Atenção',,1)
	Return
	
EndIf

_oBrwEfe:SetAlias('Z12')
_oBrwEfe:SetDescription( 'Efetivação dos Pedidos de Funcionários' )
_oBrwEfe:SetMenuDef('XXXXXXXX')

_oBrwEfe:AddButton( 'Efetivar'			, {|| AOMS070EFE(1)	} ,, 4 , 0 , .F. , 1 )
_oBrwEfe:AddButton( 'Efetivar Vários'	, {|| AOMS070EFE(2)	} ,, 4 , 0 , .F. , 2 )
_oBrwEfe:AddButton( 'Imprimir'			, {|| U_ROMS011()	} ,, 1 , 0 , .F. , 3 )
_oBrwEfe:AddButton( 'Relação Efet.'		, {|| AOMS070RLT()	} ,, 1 , 0 , .F. , 4 )
_oBrwEfe:AddButton( 'Estornar'			, {|| AOMS070EFE(3)	} ,, 4 , 0 , .F. , 5 )
_oBrwEfe:AddButton( 'Cancelar'			, {|| AOMS070EFE(4)	} ,, 4 , 0 , .F. , 6 )

_oBrwEfe:AddLegend( 'Z12_STATUS == "I"' , 'GREEN'	, 'Solicitação em Aberto' )
_oBrwEfe:AddLegend( 'Z12_STATUS == "C"' , 'BLACK'	, 'Solicitação Cancelada' )
_oBrwEfe:AddLegend( 'Z12_STATUS == "E"' , 'RED'		, 'Solicitação Efetivada' )

_oBrwEfe:Activate()

Return

Static Function AOMS070EFE( _nOpc )

Local _aDadSol	:= {}
Local _cPerg	:= 'AOMS070E'
Local _cQuery	:= ''
Local _cAlias	:= ''

If _nOpc == 1
	
	If Z12->Z12_STATUS == 'I'
	
		If U_ITMsg( 'Confirma a efetivação da solicitação ['+ Z12->Z12_CODIGO +'] ?' , 'Atenção!',,2,2,2 )
			
			FWMsgRun( ,{|| AOMS070GEF() },'Aguarde!' ,'Efetivando o pedido...'    )

		Else
			
			U_ITMsg( 'Operação cancelada pelo usuário!' , "Atenção",,1 )
			
		EndIf
	
	Else
		
		U_ITMsg( 'O registro selecionado '+ IIf( Z12->Z12_STATUS == 'C' , 'foi Cancelado!' , 'já foi Efetivado! [Pedido:'+ Z12->Z12_PEDSC5 +']' ) ,"Atenção",,1 )
		
	EndIf
	
ElseIf _nOpc == 2
	If Pergunte( _cPerg )
		
		_cQuery := " SELECT "
		_cQuery += "    Z12.Z12_CODIGO AS CODZ12, "
		_cQuery += "    Z12.R_E_C_N_O_ AS REGZ12 "
		_cQuery += " FROM  "+ RetSqlName('Z12') +" Z12 "
		_cQuery += " WHERE "+ RetSqlCond('Z12')
		_cQuery += " AND Z12.Z12_DATA   BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"' "
		_cQuery += " AND Z12.Z12_CODIGO BETWEEN '"+ MV_PAR03       +"' AND '"+ MV_PAR04       +"' "
		_cQuery += " AND Z12.Z12_STATUS = 'I' "
		
		If !Empty( MV_PAR05 )
		_cQuery += " AND Z12.Z12_MATRIC = '"+ MV_PAR05 +"' "
		EndIf
		
		_cQuery += " ORDER BY Z12.Z12_CODIGO "
		
		_cAlias := GetNextAlias()
		
        MPSysOpenQuery( _cQuery , _cAlias)		

		(_cAlias)->( DBGoTop() )
		While (_cAlias)->( !Eof() )
			
			Z12->( DBGoTo( (_cAlias)->REGZ12 ) )
			
			aAdd( _aDadSol , {	.F.																					,;
								Z12->Z12_CODIGO																		,;
								Z12->Z12_MATRIC																		,;
								AllTrim( Posicione( 'SRA' , 1 , xFilial('SRA') + Z12->Z12_MATRIC , 'RA_NOME' ) )	,;
								Z12->Z12_VALOR																		,;
								Z12->Z12_DATA																		,;
								(_cAlias)->REGZ12																	})
			
			(_cAlias)->( DBSkip() )
		EndDo
		
		(_cAlias)->( DBCloseArea() )
		
		If Empty(_aDadSol)
			
			U_ITMsg(  'Não foram encontrados registros para processar!',"Atenção",' Verifique os filtros e tente novamente.' , ,1 )
			
		Else
			
			If U_ITListBox( 'Solicitações de compras de funcionários: ' , { '[]' , 'Código' , 'Matrícula' , 'Nome' , 'Valor' , 'Data' } , @_aDadSol , .T. , 2 , 'Selecione as solicitações que serão efetivadas:' )
			
				FWMsgRun( , {|| AOMS070GEF( _aDadSol ) }, 'Aguarde!','Efetivando o(s) pedido(s)...'   )
			
			Else
				
				U_ITMsg('Operação cancelada pelo usuário!' , 'Atenção',,1 )
				
			EndIf
			
		EndIf
		
	Else
		
		U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção',,1 )
		
	EndIf

ElseIf _nOpc == 3
	
	If Z12->Z12_STATUS == 'E'
	
		If U_ITMsg( 'Confirma o estorno da efetivação da solicitação ['+ Z12->Z12_CODIGO +'] ?' , 'Atenção!',,2,2,2 )
			
			FWMsgRun( , {|| AOMS070EXC() }, 'Aguarde!','Estornando o pedido...'   )
			
		EndIf
	
	Else
	
		U_ITMsg( 'A solicitação atual não está efetivada!','Atenção','Somente solicitações efetivadas podem ser estornadas.',1  )
	
	EndIf

ElseIf _nOpc == 4
	
	If Z12->Z12_STATUS == 'E'
		
		U_ITMsg( 'A solicitação atual encontra-se efetivada e não poderá ser cancelada!','Atenção','Para cancelar a solicitação é necessário estornar o pedido de venda.',1)				
		
		If U_ITMsg( 'Deseja efetuar o estorno da solicitação ['+ Z12->Z12_CODIGO +'] ?' , 'Atenção!',,3,2,2 )
			
			FWMsgRun( , {|| AOMS070EXC() }, 'Aguarde!','Estornando o pedido...'   )
			
		EndIf
		
	ElseIf Z12->Z12_STATUS == 'C'
	
		U_ITMsg( 'A solicitação atual já foi cancelada! ', 'Atenção','Verifique o registro selecionado. ',1)
	
	EndIf
	
	If Z12->Z12_STATUS == 'I'
	
		If U_ITMsg( 'Confirma o cancelamento da solicitação ['+ Z12->Z12_CODIGO +'] ?' , 'Atenção!',,3,2,2 )
			
			FWMsgRun( , {|| AOMS070CAN() }, 'Aguarde!','Cancelando o pedido...'   )
			
		EndIf
	
	EndIf

EndIf

_oBrwEfe:Refresh()

Return

/*
===============================================================================================================================
Programa--------: AOMS070GEF
Autor-----------: Alexandre Villar
Data da Criacao-: 31/08/2015
===============================================================================================================================
Descrição-------: Rotina para gravar a efetivação das solicitações
===============================================================================================================================
Parametros------: _aDadSol - array com dados de usuários do pedido
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070GEF( _aDadSol )

Local _lRet		:= .F.
Local _aCabec	:= {}
Local _aItens	:= {}
Local _aLog		:= {}
Local _cPedSC5	:= ''
Local _cLocal	:= U_ITGETMV( 'IT_ARMPFUN' , '  '			)
Local _cTipOpe	:= U_ITGETMV( 'IT_TIPOPER' , '02'			)
Local _cFilPed	:= U_ITGETMV( 'IT_FILPEDF' , xFilial('SC5')	)
Local _nDiaEnt	:= U_ITGETMV( 'IT_DIASENT' ,   2			)
Local _cFilBkp	:= cFilAnt
Local _nI		:= 0
Local _nConv	:= 0
Local _cTpConv	:= ''
Local _nNewFat	:= 0
Local _nQtd2UM	:= 0
Local _lFluxoNormal := .T.

Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.

Default _aDadSol	:= {}

Begin Sequence 

   If Empty( _aDadSol )
	  _aDadSol := { { .T. } }
   EndIf

   For _nI := 1 To Len( _aDadSol )
	
	   If _aDadSol[_nI][01]
	
		  If Len( _aDadSol[_nI] ) > 1
			
			 DBSelectArea('Z12')
			 Z12->( DBGoTo( _aDadSol[_nI][07] ) )
		
		  EndIf
		
		  DBSelectArea("Z13")
		  Z13->( DBSetOrder(1) )
		  If Z13->( DBSeek( xFilial('Z13') + Z12->Z12_CODIGO ) )
		
			 DBSelectArea('SRA')
			 SRA->( DBSetOrder(1) )
			 If SRA->( DBSeek( xFilial('SRA') + Z12->Z12_MATRIC ) )
				
				If SRA->RA_FILIAL <> xFilial('SRA')
					
				   aAdd( _aLog , { 'O funcionário da matrícula ['+ Z12->Z12_MATRIC +'] não está cadastrado na Filial '+ xFilial('SRA') +'!' } )
					
				ElseIf Empty( SRA->RA_DEMISSA ) .And. SRA->RA_SITFOLH <> 'D'
				
				   DBSelectArea('SA1')
				   SA1->( DBSetOrder(3) )
				   If SA1->( DBSeek( xFilial('SA1') + SubStr( SRA->RA_CIC + Space( TamSX3('A1_CGC')[01] ) , 1 , TamSX3('A1_CGC')[01] ) ) )
					
					  If SA1->A1_MSBLQL == '1'
							
						 aAdd( _aLog , { 'O funcionário da matrícula ['+ Z12->Z12_MATRIC +'] está com o cadastrado de "Cliente" bloqueado no sistema!' } )
							
					  Else
							
						 If Empty( SA1->A1_LC ) .Or. SA1->A1_LC < Z12->Z12_VALOR
								
							aAdd( _aLog , { 'O funcionário da solicitação ['+ Z12->Z12_CODIGO +'] está com o cadastrado de "Cliente" com limite de crédito insuficiente para o pedido atual!' } )
							
						 Else
								
							_lRet := .T.
							
						 EndIf
							
					  EndIf
					
				   Else
					
					  aAdd( _aLog , { 'O funcionário da matrícula ['+ Z12->Z12_MATRIC +'] não está cadastrado como "Cliente" no sistema!' } )
					
				   EndIf
					
				Else
				
				   aAdd( _aLog , { 'O funcionário da matrícula ['+ Z12->Z12_MATRIC +'] não está ativo no sistema!' } )
				
				EndIf
			 Else
				aAdd( _aLog , { 'A Matrícula ou CPF informado ['+ Z12->Z12_MATRIC +'] não é válido!' } )
				
			 EndIf
			
			 If _lRet
			
				While Z13->( !Eof() ) .And. Z13->( Z13_FILIAL + Z13_CODPED ) == xFilial('Z13') + Z12->Z12_CODIGO
				
//					_cLocal		:= U_ITGETMV( 'IT_ARMPFUN' , '  '			)				
					_nConv		:= Posicione( "SB1" , 1 , xFilial("SB1") + Z13->Z13_CODPRD , "B1_CONV" )
					_cTpConv	:= SB1->B1_TIPCONV
					_nNewFat	:= SB1->B1_I_FATCO
					_nQtd2UM	:= 0
					If Empty(_cLocal)
					   _cLocal1:=Posicione( "SBZ" , 1 , xFilial("SBZ") + Z13->Z13_CODPRD , "BZ_LOCPAD" )
					Else   
					   _cLocal1:=_cLocal
					EndIf					
					
					If _cTpConv == "M"
						_nQtd2UM := IIf( _nConv == 0 , _nNewFat * Z13->Z13_QTD , _nConv * Z13->Z13_QTD )
					Else
						_nQtd2UM := IIf( _nConv == 0 , Z13->Z13_QTD / _nNewFat , Z13->Z13_QTD / _nConv )
					EndIf
					
					aAdd( _aItens , {	{ "C6_FILIAL"	, _cFilPed						   		, Nil },;
										{ "C6_ITEM"   	, StrZero( Val( Z13->Z13_ITEM ) , 2 )	, Nil },;
										{ "C6_PRODUTO"	, Z13->Z13_CODPRD						, Nil },;
										{ "C6_UM"    	, SB1->B1_UM							, Nil },;
										{ "C6_QTDVEN" 	, Z13->Z13_QTD							, Nil },;
										{ "C6_UNSVEN" 	, _nQtd2UM								, Nil },;
										{ "C6_LOCAL"  	, _cLocal1								, Nil },;
										{ "C6_PEDCLI" 	, Z13->Z13_CODPED						, Nil },;
										{ "C6_I_LIBPE" 	, ''									, Nil },;
										{ "C6_PRCVEN" 	, Z13->Z13_VUNIT						, Nil },;
										{ "C6_I_BLPRC"  , ''									, Nil },;
										{ "C6_ENTREGA"	, _ddtoper + _nDiaEnt					, Nil }})
				   Z13->( DBSkip() )
				EndDo
				
				_aCabec := {	{ "C5_FILIAL"  	, _cFilPed													, Nil },;
								{ "C5_TIPO"   	, "N"														, Nil },;
								{ "C5_CLIENTE"	, SA1->A1_COD												, Nil },;
								{ "C5_LOJACLI"	, SA1->A1_LOJA												, Nil },;
								{ "C5_TIPOCLI"	, 'F'													 	, Nil },;
								{ "C5_CONDPAG"	, '001'													 	, Nil },;
								{ "C5_VEND1"	, SA1->A1_VEND												, Nil },;
								{ "C5_VEND2"	, Posicione('SA3',1,xFilial('SA3')+SA1->A1_VEND,'A3_SUPER')	, Nil },;
								{ "C5_VEND3"	, SA3->A3_GEREN												, Nil },;
								{ "C5_EMISSAO"	, _ddtoper													, Nil },;
								{ "C5_MENNOTA" 	, 'Venda direta à funcionários.'							, Nil },;
								{ "C5_TPFRETE" 	, 'C'														, Nil },;
								{ "C5_I_OBPED" 	, 'Pedido Automático - AOMS070'								, Nil },;
								{ "C5_I_DTENT" 	, _ddtoper + _nDiaEnt										, Nil },;
								{ "C5_I_OPER"	, _cTipOpe													, Nil },;
								{ "C5_TRANSP" 	, ''														, Nil } }
				
				Begin Transaction
				
				   cFilAnt := _cFilPed
				
				   If !SM0->( DBSeek( cEmpAnt + cFilAnt ) )
				      U_ITMsg( "Falha ao posicionar na Filial correta para geração dos pedidos. Empresa: " + cEmpAnt + " Filial: " + cFilAnt,"Atenção",,1 )
				   EndIf
				
				   cNumEmp := SM0->M0_CODIGO + AllTrim(SM0->M0_CODFIL)
				
				   FWMsgRun( , {|| MSEXECAUTO( {|x,y,z| Mata410(x,y,z) } , _aCabec , _aItens , 3 ) }, "Aguarde!","Gerando o pedido de venda..."   ) 
				
				   _cFilSC5	:= SC5->C5_FILIAL
				   _cPedSC5	:= SC5->C5_NUM
				   cFilAnt		:= _cFilBkp
				
				   If !SM0->( DBSeek( cEmpAnt + cFilAnt ) )
				      U_ITMsg( "Falha ao posicionar o retorno na Filial atual. Empresa: " + cEmpAnt + " Filial: " + cFilAnt,"Atenção",,1 )
				   EndIf
				
				   cNumEmp := SM0->M0_CODIGO + AllTrim(SM0->M0_CODFIL)
				
				   If Empty( _cPedSC5 ) .Or. lMsErroAuto
				
				      If ( __lSx8 )
					     RollBackSX8()
				      EndIf
					
				      U_ITMsg( 'Falhou ao gerar o Pedido de Venda automaticamente, verifique o registro de Log!' , 'Atenção',,1 )
				      MostraErro()
				      DisarmTransaction()
				      MSUnLockAll()
					
				      _lFluxoNormal := .F. 
			          _aLog := {} 
			          	
				   Else
				
				      If ( __lSx8 )
					     ConfirmSX8()
				      EndIf
					
				      RecLock( "Z12" , .F. )
				      Z12->Z12_PEDSC5	:= _cFilSC5 + _cPedSC5
				      Z12->Z12_STATUS	:= 'E'
				      Z12->( MSUnLock() )
					
				      aAdd( _aLog , { "Criado o Pedido de Venda [Filial: "+ _cFilSC5 +'/'+"Pedido: "+ _cPedSC5 +"] para a solicitação ["+ Z12->Z12_CODIGO +"]" } )
				   EndIf
				
				End Transaction
				
				MSUnLockAll()
				
				If ! _lFluxoNormal 
				   Break
				EndIf 
				
				_aCabec := {}
				_aItens	:= {}
			 EndIf
		  Else
			 aAdd( _aLog , { 'Não foram encontrados os ítens para a solicitação ['+ Z12->Z12_CODIGO +'] da matrícula ['+ Z12->Z12_MATRIC +']!' } )
		  EndIf
	   EndIf
   Next _nI

End Sequence  

If Empty(_aLog)
   _aLog := { { 'Não foi processado nenhum registro!' } }
EndIf

U_ITListBox( 'Resumo do processamento:' , {'Mensagens'} , _aLog , .F. , 1 )

Return

/*
===============================================================================================================================
Programa--------: AOMS070EXC
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para estornar a efetivação e excluir o pedido de venda existente
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070EXC()

Local _aCab		:= {}
Local _aItens	:= {}
Local _cFilBkp	:= cFilAnt
Local _cFilPed	:= U_ITGETMV( 'IT_FILPEDF' , xFilial('SC5')	)

Private lMsErroAuto	:= .F.

If _cFilPed <> cFilAnt

	cFilAnt := _cFilPed
	
	If !SM0->( DBSeek( cEmpAnt + cFilAnt ) )
	     U_ITMsg( "Falha ao posicionar na Filial correta para geração dos pedidos. Empresa: " + cEmpAnt + " Filial: " + cFilAnt,"Atenção",,1 )
	EndIf
	
	cNumEmp := SM0->M0_CODIGO + AllTrim(SM0->M0_CODFIL)

EndIf

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( Z12->Z12_PEDSC5 ) )

	_aCab	:= {}
	_aItens	:= {}
	
	_aCab := {	{ "C5_FILIAL"	, SC5->C5_FILIAL	, nil },;
				{ "C5_NUM"    	, SC5->C5_NUM		, nil },;
				{ "C5_TIPO"   	, SC5->C5_TIPO		, nil },;
				{ "C5_CLIENTE"	, SC5->C5_CLIENTE	, nil },;
				{ "C5_LOJACLI"	, SC5->C5_LOJACLI	, nil },;
				{ "C5_CLIENT" 	, SC5->C5_CLIENT	, nil },;
				{ "C5_LOJAENT"	, SC5->C5_LOJAENT	, nil },;
				{ "C5_TRANSP" 	, SC5->C5_TRANSP	, nil },;
				{ "C5_CONDPAG"	, SC5->C5_CONDPAG	, nil },;
				{ "C5_EMISSAO"	, SC5->C5_EMISSAO	, nil },;
				{ "C5_MOEDA"  	, SC5->C5_MOEDA		, Nil },;
				{ "C5_MENPAD" 	, SC5->C5_MENPAD	, nil },;
				{ "C5_LIBEROK"	, SC5->C5_LIBEROK	, Nil },;
				{ "C5_VEND1"  	, SC5->C5_VEND1		, Nil },;
				{ "C5_TIPLIB" 	, SC5->C5_TIPLIB	, Nil } }
        
	DBSelectArea("SC6")
	SC6->( DBSetOrder(1) )
	If SC6->( DBSeek( Z12->Z12_PEDSC5 ) )
	
		While SC6->( C6_FILIAL + C6_NUM ) == Z12->Z12_PEDSC5
			
			aAdd( _aItens , {	{ "C6_FILIAL"	, SC6->C6_FILIAL	, nil },;
								{ "C6_ITEM"   	, SC6->C6_ITEM		, nil },;
								{ "C6_PRODUTO"	, SC6->C6_PRODUTO	, nil },;
								{ "C6_UM"     	, SC6->C6_UM		, nil },;
								{ "C6_QTDVEN" 	, SC6->C6_QTDVEN	, nil },;
								{ "C6_PRCVEN" 	, SC6->C6_PRCVEN	, nil },;
								{ "C6_VALOR"  	, SC6->C6_VALOR		, nil },;
								{ "C6_TES"    	, SC6->C6_TES		, nil },;
								{ "C6_LOCAL"  	, SC6->C6_LOCAL		, nil },;
								{ "C6_CF"     	, SC6->C6_CF		, nil },;
								{ "C6_ENTREG" 	, SC6->C6_ENTREG	, nil },;
								{ "C6_LOJA"   	, SC6->C6_LOJA		, nil },;
								{ "C6_NUM"    	, SC6->C6_NUM		, nil },;
								{ "C6_PEDCLI" 	, SC6->C6_PEDCLI	, nil },;
								{ "C6_DESCRI" 	, SC6->C6_DESCRI	, nil },;
								{ "C6_PRUNIT" 	, SC6->C6_PRUNIT	, nil }})
		SC6->( DBSkip() )
        EndDo
        
	EndIf
	
	lMSErroAuto := .F.
	
	MSExecAuto( { |x,y,z| Mata410(x,y,z) } , _aCab , _aItens , 5 )
	
	If lMSErroAuto
	
		Mostraerro()
		
	Else
	
		RecLock( 'Z12' , .F. )
		Z12->Z12_PEDSC5	:= ''
		Z12->Z12_STATUS	:= 'I'
		Z12->( MSUnLock() )
		
		U_ITMsg( 'Pedido estornado com sucesso!' , "Concluído",,2 )
		
	EndIf

Else

	U_ITMsg( 	'Não foi encontrado o pedido no Financeiro  relacionado à solicitação selecionada!','Atenção',;
						'O STATUS da solicitação será estornado  porém é recomendado verificar se o título foi realmente excluído no  Financeiro.',3 )
	
	RecLock( 'Z12' , .F. )
	Z12->Z12_PEDSC5	:= ''
	Z12->Z12_STATUS	:= 'I'
	Z12->( MSUnLock() )
	
	U_ITMsg( 'Pedido estornado com sucesso!' ,"Concluído",,2 )

EndIf

If cFilAnt <> _cFilBkp

	cFilAnt := _cFilBkp
	
	If !SM0->( DBSeek( cEmpAnt + cFilAnt ) )
	     U_ITMsg( "Falha ao posicionar o retorno na Filial atual. Empresa: " + cEmpAnt + " Filial: " + cFilAnt,"Atenção",,1 )
	EndIf
	
	cNumEmp := SM0->M0_CODIGO + AllTrim(SM0->M0_CODFIL)

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS070P
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para zerar as senhas cadastradas para os funcionários
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS070P()

Local _lExec	:= .F.
Local _nOpc		:= 0
Local _oDlgRes	:= Nil
Local _cMatAux	:= Space(11)
Local _oFont	:= TFont():New( "Arial" ,, 14 ,, .F. ,,,, .T. , .F. )
Local _xAcesso	:= .T.//U_ITACSUSR( 'ZZL_ADMPFU' , 'S' )

//====================================================================================================
// Validação do acesso do usuário
//====================================================================================================
If ValType( _xAcesso ) == 'N' .And. _xAcesso == 0

	U_ITMsg( 'Usuário não está cadastrado na Gestão de Usuários do Configurador Italac!',"Atenção",,1 )
	Return

ElseIf ( ValType( _xAcesso ) == 'L' .And. !_xAcesso ) .Or. ValType( _xAcesso ) <> 'L'
	
	U_ITMsg( 'Usuário sem acesso à rotina de "reset" de senha dos funcionários!',"Atenção",,1 )
	Return
	
EndIf

DEFINE DIALOG _oDlgRes FROM 0,0 TO 100,230 PIXEL

	_oSay1	:= TSay():New( 008 , 040 , {|| 'Matrícula/CPF' } , _oDlgRes ,,,,,, .T. ,,, 200 , 20 )
	_oTGet1	:= TGet():New( 018 , 035 , {|u| If( PCount() > 0 , _cMatAux := u , _cMatAux ) }	, _oDlgRes , 050 , 009 , "@!"  ,, 0 ,,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, '_cMatAux' ,,,, )
    
	@036,010 BUTTON _oBtn1 PROMPT "Confirmar"	ACTION ( _nOpc := 1 , _oDlgRes:End() ) SIZE 050,012 OF _oDlgRes PIXEL
	@036,060 BUTTON _oBtn2 PROMPT "Cancelar"	ACTION ( _nOpc := 2 , _oDlgRes:End() ) SIZE 050,012 OF _oDlgRes PIXEL

ACTIVATE DIALOG _oDlgRes CENTERED

If _nOpc == 1
	
	DBSelectArea('SRA')
	SRA->( DBSetOrder(1) )
	If SRA->( DBSeek( xFilial('SRA') + AllTrim( _cMatAux ) ) )
		
		_lExec := .T.
	
	Else
	
		DBSelectArea('SRA')
		SRA->( DBSetOrder(5) )
		If SRA->( DBSeek( xFilial('SRA') + SubStr( _cMatAux + Space( TamSX3('RA_CIC')[01] ) , 1 , TamSX3('RA_CIC')[01] ) ) )
			
			While SRA->( !Eof() ) .And. SRA->( RA_FILIAL + RA_CIC ) == xFilial('SRA') + SubStr( _cMatAux + Space( TamSX3('RA_CIC')[01] ) , 1 , TamSX3('RA_CIC')[01] )
				
				If Empty( SRA->RA_DEMISSA ) .And. SRA->RA_SITFOLH <> 'D'
				
					_lExec := .T.
					Exit
					
				EndIf
			
			SRA->( DBSkip() )
			EndDo
			
		EndIf
		
		If !_lExec
			U_ITMsg( 'A Matrícula ou CPF informado não é válido na Filial atual!',"Atenção",'Informe uma matrícula ou CPF válido para iniciar.' , ,1 )
		EndIf
		
	EndIf
	
	If _lExec
	
		If SRA->RA_FILIAL <> xFilial('SRA')
			
			U_ITMsg( 'O funcionário da matrícula atual não está cadastrado na Filial '+ xFilial('SRA') ,"Atenção", ' Verifique os dados digitados!' , 1 )
			
		ElseIf Empty( SRA->RA_DEMISSA ) .And. SRA->RA_SITFOLH <> 'D'
		
			DBSelectArea('SA1')
			SA1->( DBSetOrder(3) )
			If SA1->( DBSeek( xFilial('SA1') + SubStr( SRA->RA_CIC + Space( TamSX3('A1_CGC')[01] ) , 1 , TamSX3('A1_CGC')[01] ) ) )
				
				If SA1->A1_MSBLQL == '1'
					
					U_ITMsg( 'O funcionário da matrícula atual está com o cadastrado de "Cliente" bloqueado no sistema','Atenção',;
									'Verifique os dados digitados e o cadastro do funcionário!' , 1)
					
				Else
					
					If Empty( SA1->A1_LC ) .Or. SA1->A1_LC <= 0
						
						U_ITMsg( 'O funcionário da matrícula atual está com o cadastrado de "Cliente" sem limite de crédito para compras',"Atenção",;
						 			'Verifique os dados digitados e o cadastro do funcionário!' , 1 )
						
					Else
					    
					    _lExec := .T.
						
					EndIf
					
				EndIf
			
			Else
			
				U_ITMsg( 'O funcionário da matrícula atual não está cadastrado como "Cliente" no sistema','Atenção',;
								'Verifique os dados digitados e o cadastro do funcionário!' , 1 )
			
			EndIf
			
		Else
		
			U_ITMsg( 'O funcionário atual não está ativo no sistema!','Atenção','Verifique a situação com o Depto. de RH !' , 1 )
		
		EndIf
	
	EndIf
	
	If _lExec
	
		DEFINE DIALOG _oDlgRes FROM 0,0 TO 193,500 PIXEL
		
			TGroup():New( 002 , 002 , 016 , 040 , 'Matrícula: '			, _oDlgRes ,, CLR_GRAY , .T. )
			TGroup():New( 002 , 045 , 016 , 105 , 'CPF: '				, _oDlgRes ,, CLR_GRAY , .T. )
			TGroup():New( 020 , 002 , 034 , 250 , 'Funcionário: '		, _oDlgRes ,, CLR_GRAY , .T. )
			TGroup():New( 038 , 002 , 080 , 250 , 'Cadastrar senha: '	, _oDlgRes ,, CLR_GRAY , .T. )
			
			TSay():New( 008 , 008 , {|| SRA->RA_MAT		} , _oDlgRes ,, _oFont ,,,, .T. ,,, 030 , 10 )
			TSay():New( 008 , 050 , {|| SRA->RA_CIC		} , _oDlgRes ,, _oFont ,,,, .T. ,,, 050 , 10 )
		    TSay():New( 026 , 005 , {|| SRA->RA_NOME	} , _oDlgRes ,, _oFont ,,,, .T. ,,, 200 , 10 )
		    
		    TSay():New( 050 , 015 , {|| 'Essa rotina tem o objetivo de zerar a senha do funcionário selecionado.'	} , _oDlgRes ,, _oFont ,,,, .T. ,,, 200 , 10 )
		    TSay():New( 060 , 015 , {|| 'Após esse procedimento o funcionário terá que cadastrar uma nova senha.'	} , _oDlgRes ,, _oFont ,,,, .T. ,,, 200 , 10 )
		    
		@082,149 BUTTON _oBtn1 PROMPT "Confirmar"	ACTION ( _nOpc := 1 , _oDlgRes:End() ) SIZE 050,012 OF _oDlgRes PIXEL
		@082,200 BUTTON _oBtn2 PROMPT "Cancelar"	ACTION ( _nOpc := 2 , _oDlgRes:End() ) SIZE 050,012 OF _oDlgRes PIXEL
		
		ACTIVATE DIALOG _oDlgRes CENTERED
		
		If _nOpc == 1 .And. U_ITMsg( 'Confirma a exclusão da senha do funcionário?' , 'Atenção!',,3,2,2 )
			
			RecLock('SRA',.F.)
			SRA->RA_I_SENHA := ''
			SRA->( MSUnLock() )
			
			U_ITMsg(  'Operação realizada com sucesso!' ,'Concluído',,2 )
			
		Else
		
			U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção',,1 )
		
		EndIf
	
	EndIf

Else

	U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção',,1 )

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS070CAN
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para cancelar solicitações
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070CAN()

RecLock('Z12',.F.)
Z12->Z12_STATUS := 'C'
Z12->( MSUnLock() )

Return


/*
===============================================================================================================================
Programa--------: AOMS070NEW
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para definir novo código da Z12
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _cret - lógico indicando se conseguiu gerar novo código
===============================================================================================================================
*/
Static Function AOMS070NEW()

Local _aArea	:= FWGetArea()
Local _cRet		:= ''
Local _cQuery	:= " SELECT MAX( Z12.Z12_CODIGO ) AS CODIGO FROM "+ RETSQLNAME('Z12') +" Z12 WHERE "+ RETSQLCOND('Z12')
Local _cAlias	:= GetNextAlias()

MPSysOpenQuery( _cQuery , _cAlias)

(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->CODIGO )
	
	_cRet := Soma1( (_cAlias)->CODIGO )
	
	Z12->( DBSetOrder(1) )
	While Z12->( DBSeek( xFilial('Z12') + _cRet ) )
		_cRet := Soma1( _cRet )
	EndDo
	
	While !MayIUseCode( "Z12_CODIGO" + xFilial("SA2") + _cRet )	// verifica se esta sendo usado na memoria
		_cRet := Soma1( _cRet )									// busca o proximo número disponivel
	EndDo

Else

	_cRet := StrZero( 1 , TamSX3('Z12_CODIGO')[01] )

EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea( _aArea )

Return( _cRet )

/*
===============================================================================================================================
Programa--------: AOMS070VPV
Autor-----------: Alexandre Villar
Data da Criacao-: 24/08/2015
===============================================================================================================================
Descrição-------: Rotina para verificar se existe uma tabela de preços ativa
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS070VPV()

Local _nRegTab	:= 0
Local _lRet		:= .F.
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT COUNT(1) CONTADOR"
_cQuery += " FROM  "+ RetSqlName('Z11') +" Z11 "
_cQuery += " WHERE "+ RetSqlCond('Z11')
_cQuery += " AND Z11_FILTAB LIKE '%"+ xFilial('SE1') +"%' "
_cQuery += " AND Z11_STATUS = 'S' "
_cQuery += " AND Z11_DATINI <= '"+ DToS( _ddtoper ) +"' "
_cQuery += " AND Z11_DATFIM >= '"+ DToS( _ddtoper ) +"' "
_cQuery += " ORDER BY Z11.Z11_CODPRD "

MPSysOpenQuery( _cQuery , _cAlias)

(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_nRegTab := (_cAlias)->CONTADOR
EndIf

(_cAlias)->( DBCloseArea() )

_lRet := ( _nRegTab == 0 )

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS070RLT
Autor-----------: 
Data da Criacao-: 
Descrição-------: 
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS070RLT()

 Local _cPerg	:= 'AOMS070E' As Char
 Local _cQuery	:= '' As Char
 Local _cAlias	:= GetNextAlias() As Char
 Local _aDadSol	:= {} As Array
 
 If Pergunte( _cPerg )
	
	_cQuery := " SELECT "
	_cQuery += "     Z12_CODIGO  AS CODIGO    ,"
	_cQuery += "     Z12_MATRIC  AS MATRICULA ,"
	_cQuery += "     SRA.RA_NOME AS NOME      ,"
	_cQuery += "     Z12_VALOR   AS VALOR     ,"
	_cQuery += "     Z12_DATA    AS DT_INC    ,"
	_cQuery += "     Z12_HORA    AS HORA      ,"
	_cQuery += "     Z12_PEDSC5  AS PEDIDO    ,"
	_cQuery += "     Z12_LOCENT  AS LOCALENT   "
	_cQuery += " FROM  "+ RetSqlName('Z12') +" Z12, "+ RetSqlName('SRA') +" SRA "
	_cQuery += " WHERE "+ RetSqlCond('Z12,SRA')
	_cQuery += " AND Z12.Z12_MATRIC = SRA.RA_MAT
	_cQuery += " AND Z12.Z12_STATUS = 'E'
	_cQuery += " AND Z12.Z12_DATA   BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"' "
	_cQuery += " AND Z12.Z12_CODIGO BETWEEN '"+ MV_PAR03       +"' AND '"+ MV_PAR04       +"' "
	
	If !Empty( MV_PAR05 )
	_cQuery += " AND Z12.Z12_MATRIC = '"+ MV_PAR05 +"' "
	EndIf
	
	_cQuery += " ORDER BY Z12.Z12_CODIGO "
	
    MPSysOpenQuery( _cQuery , _cAlias)
	
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
		
		aAdd( _aDadSol , {	(_cAlias)->CODIGO															,;
							(_cAlias)->MATRICULA														,;
							AllTrim( (_cAlias)->NOME )						 							,;
							AllTrim( Transform( (_cAlias)->VALOR , '@E 999,999,999,999.99' ) )			,;
							DToC( SToD( (_cAlias)->DT_INC ) )											,;
							AllTrim( (_cAlias)->HORA )													,;
							SubStr( (_cAlias)->PEDIDO , 1 , 2 ) +'/'+ SubStr( (_cAlias)->PEDIDO , 3 )	,;
							AllTrim(Upper(U_ITRetBox( (_cAlias)->LOCALENT ,"Z12_LOCENT")))})
		
	    (_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )

	If Empty( _aDadSol )
		U_ITMsg('Não foram encontradas solicitações efetivadas com os dados informados!' , 'Atenção',,1 )
	Else
		U_ITListBox( 'Relação de solicitações "EFETIVADAS"' , {'Código','Matrícula','Nome','Valor','Data','Hora','Fil/Pedido',"Local de Entrega"} , _aDadSol , .T. , 1 ,,, {50,50,200,50,50,50,50} )
	EndIf

 Else
 
 	U_ITMsg( 'Operação cancelada pelo usuário!' , 'Atenção',,1 )
 
 EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS070L
Autor-----------: Julio de Paula Paz
Data da Criacao-: 15/05/2019
===============================================================================================================================
Descrição-------: Exibe tela para o usuário informar o Local de entrega.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS070L()
Local _lRet := .T.
Local _nOpc := 0

Begin Sequence
   DEFINE DIALOG _oDlgLoc TITLE "Local de Retirada Produtos" FROM 0,0 TO 140,260 PIXEL
	  _oSayR	 := TSay():New( 018   ,005 , {|| 'Local de Retirada: '					   }, _oDlgLoc ,,,,,, .T. ,,, 200 , 20 )
      _oLocRet   := TComboBox():New(018,050 , {|u|If(PCount()>0,_cLocEnt :=u,_cLocEnt)     }, _aLocEnt,60,20,_oDlgLoc  ,,,,,,.T.,,,,,,,,,'_cLocEnt')
   
	  @ 046,010 BUTTON _oBtn1 PROMPT "Confirmar"	ACTION ( _nOpc := 1 , _oDlgLoc:End() ) SIZE 050,012 OF _oDlgLoc PIXEL
	  @ 046,060 BUTTON _oBtn2 PROMPT "Cancelar"	ACTION ( _nOpc := 0 , _oDlgLoc:End() ) SIZE 050,012 OF _oDlgLoc PIXEL

   ACTIVATE DIALOG _oDlgLoc CENTERED

   If _nOpc == 0
      _lRet := .F.
   EndIf 

End Sequence

Return _lRet
