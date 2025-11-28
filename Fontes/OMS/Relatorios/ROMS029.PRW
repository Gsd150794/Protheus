/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |22/01/2016| Chamado 13062. Ajuste nas claúsulas ORDER BY
Alex Wallauer |29/09/2020| Chamado 34262. Remoção de bugs apontados pelo Totvs CodeAnalysis
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: ROMS029
Autor-----------: Fabiano Dias
Data da Criacao-: 30/03/2011
Descrição-------: Relatorio para demonstrar os valores de comissao de forma resumida
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS029()

Private _oFont10	:= TFont():New( "Courier New"	,, 08 ,, .F. ,,,, .F. , .F. )
Private _oFont10b	:= TFont():New( "Courier New"	,, 08 ,, .T. ,,,, .F. , .F. )
Private _oFont11b	:= TFont():New( "Courier New"	,, 09 ,, .T. ,,,, .F. , .F. )
Private _oFont12	:= TFont():New( "Courier New"	,, 10 ,, .F. ,,,, .F. , .F. )
Private _oFont12b	:= TFont():New( "Courier New"	,, 10 ,, .T. ,,,, .F. , .F. )
Private _oFont14b	:= TFont():New( "Helvetica"		,, 14 ,, .T. ,,,, .F. , .F. )
Private _oPrint		:= Nil

Private _nPagina	:= 0
Private _nLinha		:= 0100 
Private _nColIni	:= 0030
Private _nColFim	:= 2360 
Private _nQbrPag	:= 3300 
Private _nIniBox	:= 0
Private _nSpcLin	:= 50               
Private _nAjsLin	:= 10 //ajusta a altura de impressao dos dados do relatorio

Private _cPerg		:= "ROMS029"

_oPrint := TMSPrinter():New( "Fechamento da Comissão : Resumido" )
_oPrint:SetPortrait() 	// Retrato
_oPrint:SetPaperSize(9)	// Papel A4
_oPrint:StartPage()

If !Pergunte( _cPerg , .T. )
     Return
EndIf

ROMS029CAB( .F. )
ROMS029IPP(_oPrint , _nLinha , _cPerg)

Processa( {|| ROMS029RUN() } , 'Aguarde!' , 'Processando o relatorio...' )

//================================================================================
// Finaliza a Pagina e Visualiza antes de Imprimir.
//================================================================================
_oPrint:EndPage()
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa----------: ROMS029IPP
Autor-------------: Alex /w
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir a pagina de parametros do relatorio em modo grafico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029IPP( _oPrint , _nLinha , _cPerg )

Local cVlrParam	:= ""
Local nAux     	:= 0
Local _nX		:= 0
Local nqtdeCar	:= 0
Local oObj 		:= FWSX1Util():New()
Local oFont14Prb:= TFont():New( "Arial" ,, 14 ,, .T. ,,,, .T. , .F. )

oObj:AddGroup(_cPerg)
oObj:SearchGroup()
//Quantidade de caracteres para quebra de Linha
nqtdeCar:= 84

_oPrint:StartPage() // Inicia uma nova página
_nLinha += 080
_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
_nLinha += 060

For _nX:=1 to Len(oObj:aGrupo[1][2])
	nAux:= 1
	_oPrint:Say (_nLinha,_nColIni + 10,"Pergunta " + oObj:aGrupo[1][2][_nX]:CX1_ORDEM + ' : ' + AllTrim(oObj:aGrupo[1][2][_nX]:CX1_PERGUNT),oFont14Prb)
		//Verifica se eh combo
	If oObj:aGrupo[1][2][_nX]:CX1_GSC == 'C'
		cVlrParam:= &("oObj:aGrupo[1][2][_nX]:CX1_DEF"+ StrZero(&(oObj:aGrupo[1][2][_nX]:CX1_VAR01),2))
	Else
		Do Case
			Case oObj:aGrupo[1][2][_nX]:CX1_TIPO == 'C'
		 		cVlrParam:= &(oObj:aGrupo[1][2][_nX]:CX1_VAR01)
			Case oObj:aGrupo[1][2][_nX]:CX1_TIPO == 'D'
				cVlrParam:= DToC(&(oObj:aGrupo[1][2][_nX]:CX1_VAR01))
			Case oObj:aGrupo[1][2][_nX]:CX1_TIPO == 'N'
				cVlrParam:= AllTrim(Str(&(oObj:aGrupo[1][2][_nX]:CX1_VAR01)))
		EndCase
	EndIf

	While nAux <= Len(AllTrim(cVlrParam))
		_oPrint:Say (_nLinha,1200,SubStr(AllTrim(cVlrParam),nAux,nqtdeCar),oFont14Prb)
		_nLinha+= 60
		nAux+= nqtdeCar
	EndDo
	
	If Len(AllTrim(cVlrParam)) == 0
		_nLinha+= 60
	EndIf
Next _nX

_nLinha+= 60
_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)

_oPrint:EndPage()     // Finaliza a página

Return
            
/*
===============================================================================================================================
Programa----------: ROMS029CAB
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir o cabeçalho das pagina em modo grafico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029CAB( _lImpPag )

Local _cPath	:= If( IsSrvUnix() , "/" , "\" )
Local _cTitulo	:= "Fechamento da comissão - Resumido - "+ IIf( !Empty(MV_PAR01) , MesExtenso( Val( SubStr( MV_PAR01 , 1 , 2 ) ) ) + ' de ' + SubStr( MV_PAR01 , 3 , 4 ) , "" )

_nLinha := 0100

_oPrint:SayBitmap( _nLinha , _nColIni , _cPath + "system/lgrl01.bmp" , 250 , 100 )

If _lImpPag

_oPrint:Say( _nLinha		, _nColFim - 550 , "PÁGINA: " + AllTrim( Str( _nPagina ) )								, _oFont12b )

Else

_oPrint:Say( _nLinha		, _nColFim - 550 , "SIGA/ROMS029"														, _oFont12b )
_oPrint:Say( _nLinha + 100	, _nColFim - 550 , "EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL)	, _oFont12b )

EndIf

_oPrint:Say( _nLinha + 050	, _nColFim - 550 , "DATA DE EMISSÃO: "+ DToC( Date() )									, _oFont12b )

_nLinha += 050

_oPrint:Say( _nLinha , _nColFim / 002 , _cTitulo , _oFont14b , _nColFim ,,, 2 )

_nLinha += _nSpcLin
_nLinha += _nSpcLin

_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )

Return

/*
===============================================================================================================================
Programa----------: ROMS029CDR
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir o cabeçalho dos dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029CDR( _cTipo )

_oPrint:Box( _nLinha , _nColIni , _nLinha + _nSpcLin , _nColFim )

_oPrint:Say( _nLinha , _nColFim / 2 , _cTipo , _oFont14b , _nColFim ,,, 2 )

_nLinha		+= _nSpcLin
_nIniBox	:= _nLinha

_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 0010 , "Nome"				, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1020 , "Vlr.Comis.Bruto"	, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1430 , "INSS"				, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1590 , "IRRF"				, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1700 , "Vlr.Comis.Liquida"	, _oFont11b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 2050 , "% Vlr.Recebido"	, _oFont11b )

Return
            
/*
===============================================================================================================================
Programa----------: ROMS029PRD
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir os dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029PRD( _cNome , _nVlrComis , _nINSS , _nIRRF , _nVlrBase , _nVlrBonif )

Local _nPorcCom		:= 0
Local _nVlrLiq		:= 0

Default _nVlrBonif	:= 0

_nPorcCom			:= ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
_nVlrComis			-= _nVlrBonif
_nVlrLiq			:= _nVlrComis - ( _nINSS + _nIRRF )

_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 0010 , SubStr( _cNome , 1 , 57 )		  				, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1080 , Transform( _nVlrComis	, "@E 999,999,999.99" )	, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1350 , Transform( _nINSS		, "@E 999,999.99" )		, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1500 , Transform( _nIRRF		, "@E 999,999.99" )		, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1800 , Transform( _nVlrLiq		, "@E 999,999,999.99" )	, _oFont10 )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 2200 , Transform( _nPorcCom	, "@E 999.99" ) + '%'	, _oFont10 )

Return

/*
===============================================================================================================================
Programa----------: ROMS029TOT
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir os Totalizadores do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029TOT( _cNome , _nVlrComis , _nINSS , _nIRRF , _nVlrBase , _nVlrBonif )

Local _nPorcCom		:= 0
Local _nVlrLiq		:= 0

Default _nVlrBonif	:= 0

_nPorcCom	:= ( ( _nVlrComis - _nVlrBonif ) / _nVlrBase ) * 100
_nVlrLiq	:= _nVlrComis - _nVlrBonif - ( _nINSS + _nIRRF )

_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 0010 , SubStr( _cNome , 1 , 40 )						, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1080 , Transform( _nVlrComis	, "@E 999,999,999.99" )	, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1350 , Transform( _nINSS		, "@E 999,999.99" )		, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1500 , Transform( _nIRRF		, "@E 999,999.99" )		, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 1800 , Transform( _nVlrLiq		, "@E 999,999,999.99" )	, _oFont10b )
_oPrint:Say( _nLinha + _nAjsLin , _nColIni + 2200 , Transform( _nPorcCom	, "@E 999.99" ) + '%'	, _oFont10b )

Return
           
/*
===============================================================================================================================
Programa----------: ROMS029BOX
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para imprimir uma BOX no relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029BOX()

_oPrint:Box( _nIniBox , _nColIni , _nLinha , _nColFim )

Return

/*
===============================================================================================================================
Programa----------: ROMS029QPG
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para efetuar a quebra de páginas do relatório
Parametros--------: _nLinhas  - Numero de linhas que sera reduzido do tamanho do box do relatorio.
------------------: _lImpBox  - .T. - indica que imprime box
------------------: _lImpCab  - .T. - indica que imprime cabecalho de dados
------------------: _bImpBox  - Nome da funcao para impressao do box e suas divisorias
------------------: _bImpCab  - Nome da funcao para impressao do cabecalho de dados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029QPG( _nLinhas , _lImpBox , _lImpCab , _bImpBox , _bImpCab )

//================================================================================
// Quebra de pagina
//================================================================================
If _nLinha > _nQbrPag

	_nLinha := _nLinha - (_nSpcLin * _nLinhas)
	
	//================================================================================
	// Verifica se imprime o box e divisorias do relatorio
	//================================================================================
	If _lImpBox
		&_bImpBox
	EndIf
	
	//================================================================================
	// Finaliza a página atual e inicializa uma nova
	//================================================================================
	_oPrint:EndPage()
	_oPrint:StartPage()
	
	_nPagina++
	
	//================================================================================
	// Chama a impressão do cabeçalho do relatório
	//================================================================================
	ROMS029CAB( .T. )
	
	_nLinha += _nSpcLin
	_nLinha += _nSpcLin
	
	//================================================================================
	// Verifica se imprime o cabecalho dos dados
	//================================================================================
	If _lImpCab
	
		&_bImpCab
		
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS029PPG
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para endereçar o cabeçalho dos dados do relatório
Parametros--------: _cTipo  - Descrição do cabeçalho
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029PPG( _cTipo )
						
_nLinha += _nSpcLin
_nLinha += _nSpcLin

ROMS029CDR(_cTipo)

Return

/*
===============================================================================================================================
Programa----------: ROMS029QRY
Autor-------------: Fabiano Dias
Data da Criacao---: 30/03/2011
Descrição---------: Funcao criada para endereçar o cabeçalho dos dados do relatório
Parametros--------: _cAlias : Define o Alias da área de trabalho temporária que será criada
------------------: _nOpcao : Informa a opção de consulta a realizar
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029QRY( _cAlias , _nOpcao )

Local _cWhere01 := "% AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2) + "' %"

Do Case

	//================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de 
	// credito e debito dos vendedores.
	//================================================================================
	Case _nOpcao == 1
	
		BeginSql alias _cAlias
			
			SELECT
			    E3.E3_VEND       AS CODVEND ,
			    A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'C'              AS ORDENACAO
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON
			    A3.A3_COD        = E3.E3_VEND
			
			INNER JOIN %Table:SE1% E1
			ON
			    E1.E1_FILIAL    = E3.E3_FILIAL
			AND E1.E1_TIPO      = E3.E3_TIPO
			AND E1.E1_PREFIXO   = E3.E3_PREFIXO
			AND E1.E1_NUM       = E3.E3_NUM
			AND E1.E1_SERIE     = E3.E3_SERIE
			AND E1.E1_PARCELA   = E3.E3_PARCELA
			AND E1.E1_CLIENTE   = E3.E3_CODCLI
			AND E1.E1_LOJA      = E3.E3_LOJA
			
			INNER JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL    = E1.E1_FILIAL
			AND F2.F2_DOC       = E1.E1_NUM
			AND F2.F2_SERIE     = E1.E1_SERIE
			AND F2.F2_CLIENTE   = E1.E1_CLIENTE
			AND F2.F2_LOJA      = E1.E1_LOJA
			AND F2.F2_VEND1     = E3.E3_VEND
			AND F2.F2_VEND1     <> F2.F2_VEND2
			AND F2.F2_VEND2     <> ' '
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND E1.%NotDel%
			AND F2.%NotDel%
			AND E3.E3_COMIS     > 0
			%Exp:_cWhere01%
			
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 6
			
			UNION ALL
			
			SELECT
			    E3.E3_VEND       AS CODVEND ,
			    A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    SUM(E3.E3_BASE)  AS VLRRECEB,
			    'C'              AS ORDENACAO
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON
			    E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SE5% E5
			ON
			    E5.E5_DOCUMEN = E1.E1_NUMLIQ
			AND E5.E5_FILIAL  = E1.E1_FILIAL
			AND E5.E5_DOCUMEN <> ' '
			
			INNER JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL  = E5.E5_FILIAL
			AND F2.F2_DOC     = E5.E5_NUMERO
			AND F2.F2_SERIE   = E5.E5_PREFIXO
			AND F2.F2_CLIENTE = E5.E5_CLIFOR
			AND F2.F2_LOJA    = E5.E5_LOJA
			AND F2.F2_VEND1   = E3.E3_VEND
			AND F2.F2_VEND1   <> F2.F2_VEND2
			AND F2.F2_VEND2   <> ' '
			
			INNER JOIN %Table:SA3% A3
			ON
			   A3.A3_COD      = E3.E3_VEND
			
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			AND A3.%NotDel%
			AND E5.%NotDel%
			AND F2.%NotDel%
			AND E3.E3_COMIS   > 0 
			AND E1.E1_ORIGEM  = 'FINA460'
			%Exp:_cWhere01%
			
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 6
			
			UNION ALL
			
			SELECT
			    E3.E3_VEND       AS CODVEND ,
			    A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    TO_NUMBER(NULL)  AS VLRRECEB,
			    'D'              AS ORDENACAO
			FROM %Table:SE3% E3,
			     %Table:SA3% A3,
			     (   SELECT DISTINCT
			             F2.F2_VEND1,
			             D1.D1_FILIAL,
			             D1.D1_DOC,
			             D1.D1_SERIE,
			             D1.D1_FORNECE,
			             D1.D1_LOJA
			         FROM %Table:SD1% D1 , %Table:SF2% F2
			         WHERE
			             D1.%NotDel%
			         AND F2.%NotDel%
			         AND F2.F2_FILIAL  = D1.D1_FILIAL
			         AND F2.F2_DOC     = D1.D1_NFORI
			         AND F2.F2_SERIE   = D1.D1_SERIORI
			         AND F2.F2_CLIENTE = D1.D1_FORNECE
			         AND F2.F2_LOJA    = D1.D1_LOJA
			         AND F2.F2_VEND1   <> F2.F2_VEND2
			         AND F2.F2_VEND2   <> ' '
			     ) COORDENAD
			
			WHERE 
			    E3.%NotDel%
			AND A3.%NotDel%
			AND E3.E3_FILIAL = COORDENAD.D1_FILIAL
			AND E3.E3_NUM    = COORDENAD.D1_DOC
			AND E3.E3_SERIE  = COORDENAD.D1_SERIE
			AND E3.E3_CODCLI = COORDENAD.D1_FORNECE
			AND E3.E3_LOJA   = COORDENAD.D1_LOJA
			AND E3.E3_VEND   = COORDENAD.F2_VEND1
			AND A3.A3_COD    = E3.E3_VEND
			AND E3.E3_TIPO   = 'NCC'
			%Exp:_cWhere01%
			
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 6
			
			UNION ALL
			
			SELECT
			    E3.E3_VEND       AS CODVEND ,
			    A3.A3_NOME       AS NOMEVEND,
			    A3.A3_I_DEDUC    AS DEDUCAO ,
			    SUM(E3.E3_COMIS) AS COMISSAO,
			    TO_NUMBER(NULL)  AS VLRRECEB,
			    'D'              AS ORDENACAO
			FROM %Table:SE3% E3
			
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND       = A3.A3_COD
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND E3.E3_TIPO    = 'NCC'
			AND A3.A3_COD     <> A3.A3_SUPER
			AND A3.A3_SUPER   <> ' ' 
			%Exp:_cWhere01%
			AND E3.E3_NUM     NOT IN ( SELECT
			                               D1.D1_DOC
			                           FROM %Table:SD1% D1 , %Table:SF2% F2
			                           WHERE
			                               D1.%NotDel%
			                           AND F2.%NotDel%
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA
			                  )
			
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 6
			
			ORDER BY CODVEND , ORDENACAO
			
		EndSql
	
	//================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de
	// credito e debito dos coordenadores.
	//================================================================================
	Case _nOpcao == 2
	
		BeginSql alias _cAlias
			
			SELECT
			    E3.E3_VEND        AS CODCOORD   ,
			    A3.A3_NOME        AS NOMECOORD  ,
			    A3.A3_I_DEDUC     AS DEDUCAO    ,
			    'C'               AS ORDENACAO,
			    SUM( E3.E3_COMIS) AS COMISSAO   ,
			    SUM( E3.E3_BASE)  AS VLRRECEB
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON
			    E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SF2% F2
			ON
			    F2.F2_FILIAL    = E1.E1_FILIAL
			AND F2.F2_DOC       = E1.E1_NUM
			AND F2.F2_SERIE     = E1.E1_SERIE
			AND F2.F2_CLIENTE   = E1.E1_CLIENTE
			AND F2.F2_LOJA      = E1.E1_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON
			    A3.A3_COD     = E3.E3_VEND
			
			WHERE
			    E3.%NotDel%
			AND F2.%NotDel%
			AND A3.%NotDel%
			AND E3.E3_COMIS   > 0  
			%Exp:_cWhere01%
			AND (  ( F2.F2_VEND2  = ' '          AND F2.F2_VEND1 = E3.E3_VEND )
			    OR ( F2.F2_VEND1  <> F2.F2_VEND2 AND F2.F2_VEND2 = E3.E3_VEND )
			    OR ( F2.F2_VEND3  = E3.E3_VEND   ) )
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 4
			
			UNION ALL
			
			SELECT
			    E3.E3_VEND       AS CODCOORD   ,
			    A3.A3_NOME       AS NOMECOORD  ,
			    A3.A3_I_DEDUC    AS DEDUCAO    ,
			    'C'              AS ORDENACAO,
			    SUM(E3.E3_COMIS) AS COMISSAO   ,
			    SUM(E3.E3_BASE)  AS VLRRECEB
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SE1% E1
			ON
			    E1.E1_FILIAL  = E3.E3_FILIAL
			AND E1.E1_TIPO    = E3.E3_TIPO
			AND E1.E1_PREFIXO = E3.E3_PREFIXO
			AND E1.E1_NUM     = E3.E3_NUM
			AND E1.E1_SERIE   = E3.E3_SERIE
			AND E1.E1_PARCELA = E3.E3_PARCELA
			AND E1.E1_CLIENTE = E3.E3_CODCLI
			AND E1.E1_LOJA    = E3.E3_LOJA
			
			INNER JOIN %Table:SA3% A3
			ON
			    A3.A3_COD = E3.E3_VEND
			    
			,   (    SELECT DISTINCT
			             E5.E5_FILIAL,
			             E5.E5_DOCUMEN,
			             Case
			                 WHEN F2.F2_VEND2 = ' '          THEN F2.F2_VEND1
			                 WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN F2.F2_VEND2
			                 WHEN F2.F2_VEND3 <> ' '         THEN F2.F2_VEND3
			             END AS CODANL
			         FROM %Table:SE5% E5
			         JOIN %Table:SF2% F2
			         ON
			             F2.F2_FILIAL  = E5.E5_FILIAL
			         AND F2.F2_DOC     = E5.E5_NUMERO
			         AND F2.F2_SERIE   = E5.E5_PREFIXO
			         AND F2.F2_CLIENTE = E5.E5_CLIFOR
			         AND F2.F2_LOJA    = E5.E5_LOJA
			         WHERE 
			             E5.%NotDel%
			         AND F2.%NotDel%
			         AND E5.E5_SITUACA <> 'C'
			         AND E5.E5_DOCUMEN <> ' '
			         GROUP BY
			             E5.E5_FILIAL ,
			             E5.E5_DOCUMEN,
			             Case
			                 WHEN F2.F2_VEND2 = ' '          THEN F2.F2_VEND1
			                 WHEN F2.F2_VEND1 <> F2.F2_VEND2 THEN F2.F2_VEND2
			                 WHEN F2.F2_VEND3 <> ' '         THEN F2.F2_VEND3
			             END
			) DADOSLIQ
			WHERE
			    E3.%NotDel%
			AND E1.%NotDel%
			AND A3.%NotDel%
			AND E3.E3_VEND    = DADOSLIQ.CODANL
			AND E1.E1_NUMLIQ  = DADOSLIQ.E5_DOCUMEN
			AND E1.E1_FILIAL  = DADOSLIQ.E5_FILIAL
			AND E3.E3_COMIS   > 0   
			%Exp:_cWhere01%
			AND E1.E1_ORIGEM  = 'FINA460'
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 4
			
			UNION ALL
			
			SELECT 
			    E3.E3_VEND       AS CODCOORD   ,
			    A3.A3_NOME       AS NOMECOORD  ,
			    A3.A3_I_DEDUC    AS DEDUCAO    ,
			    'D'              AS ORDENACAO,
			    SUM(E3.E3_COMIS) AS COMISSAO   ,
			    SUM(E3.E3_BASE)  AS VLRRECEB
			FROM %Table:SE3% E3
			JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			
			JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			AND E3.E3_TIPO    = 'NCC'
			%Exp:_cWhere01%
			AND E3.E3_NUM     IN ( SELECT 
			                           D1.D1_DOC
			                       FROM %Table:SD1% D1 , %Table:SF2% F2
			                       WHERE
			                           D1.%NotDel%
			                       AND F2.%NotDel%
			                       AND E3.E3_FILIAL  = D1.D1_FILIAL
			                       AND E3.E3_NUM     = D1.D1_DOC
			                       AND E3.E3_SERIE   = D1.D1_SERIE
			                       AND E3.E3_CODCLI  = D1.D1_FORNECE
			                       AND E3.E3_LOJA    = D1.D1_LOJA
			                       AND F2.F2_FILIAL  = D1.D1_FILIAL
			                       AND F2.F2_DOC     = D1.D1_NFORI
			                       AND F2.F2_SERIE   = D1.D1_SERIORI
			                       AND F2.F2_CLIENTE = D1.D1_FORNECE
			                       AND F2.F2_LOJA    = D1.D1_LOJA
			                       AND (  ( F2.F2_VEND2 = ' '          AND F2.F2_VEND1 = E3.E3_VEND )
			                           OR ( F2.F2_VEND1 <> F2.F2_VEND2 AND F2.F2_VEND2 = E3.E3_VEND )
			                           OR ( F2.F2_VEND3 = E3.E3_VEND   ) )
			)
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 4
			
			UNION ALL
			
			SELECT 
			    E3.E3_VEND       AS CODCOORD   ,
			    A3.A3_NOME       AS NOMECOORD  ,
			    A3.A3_I_DEDUC    AS DEDUCAO    ,
			    'D'              AS ORDENACAO,
			    SUM(E3.E3_COMIS) AS COMISSAO   ,
			    SUM(E3.E3_BASE)  AS VLRRECEB
			FROM %Table:SE3% E3
			
			INNER JOIN %Table:SA3% A3
			ON
			    E3.E3_VEND    = A3.A3_COD
			    
			INNER JOIN %Table:SA1% A1
			ON
			    A1.A1_COD     = E3.E3_CODCLI
			AND A1.A1_LOJA    = E3.E3_LOJA
			
			WHERE
			    E3.%NotDel%
			AND A3.%NotDel%
			AND A1.%NotDel%
			AND E3.E3_TIPO    = 'NCC'
			AND A3.A3_SUPER   = ' '  
			%Exp:_cWhere01%
			AND E3.E3_NUM     NOT IN ( SELECT
			                               D1.D1_DOC
			                           FROM %Table:SD1% D1 , %Table:SF2% F2
			                           WHERE
			                               D1.%NotDel%
			                           AND F2.%NotDel%
			                           AND E3.E3_FILIAL  = D1.D1_FILIAL
			                           AND E3.E3_NUM     = D1.D1_DOC
			                           AND E3.E3_SERIE   = D1.D1_SERIE
			                           AND E3.E3_CODCLI  = D1.D1_FORNECE
			                           AND E3.E3_LOJA    = D1.D1_LOJA
			                           AND F2.F2_FILIAL  = D1.D1_FILIAL
			                           AND F2.F2_DOC     = D1.D1_NFORI
			                           AND F2.F2_SERIE   = D1.D1_SERIORI
			                           AND F2.F2_CLIENTE = D1.D1_FORNECE
			                           AND F2.F2_LOJA    = D1.D1_LOJA
			)
			GROUP BY E3.E3_VEND , A3.A3_NOME , A3.A3_I_DEDUC , 4
			
			ORDER BY CODCOORD , ORDENACAO
			
		EndSql

EndCase

Return

/*
===============================================================================================================================
Programa--------: ROMS029RUN
Autor-----------: Fabiano Dias
Data da Criacao-: 30/03/2011
Descrição-------: Função que Processa a impressão dos dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS029RUN()

Local _cAlias    := GetNextAlias() 
Local _cAliasVend:= GetNextAlias() 

Local _aVendedor:= {}
Local _aCoordena:= {}
Local _aValALM	:= {}  

Local _aImpostos:= {} 

Local _nPosicao := 0   

//Variaveis de controle dos totalizadores dos vendedores
Local _nTotVComi:= 0
Local _nTotVINSS:= 0
Local _nTotVIRRF:= 0
Local _nTotVBase:= 0
Local _nTotVBoni:= 0

//Variaveis de controle dos totalizadores dos coordenadores
Local _nTotCComi:= 0
Local _nTotCINSS:= 0
Local _nTotCIRRF:= 0
Local _nTotCBase:= 0
Local _nTotCBoni:= 0
              
//Variaveis de controle do total geral
Local _nVlrComis:= 0
Local _nINSS	:= 0
Local _nIRRF    := 0   
Local _nVlrBase := 0
Local _nVlrBoni	:= 0

Local _nValBnf  := 0 , x

If Empty(MV_PAR01)
	MsgInfo("Favor preencher o parâmetro: Mes/Ano antes de imprimir este relatório.")
	Return
EndIf
      
	// Chama a rotina para selecao dos registros da comissao gerada para os vendedores
	MsgRun("Aguarde....Filrando comissao dos vendedores.",,{||CursorWait(),ROMS029QRY(_cAlias,1),CursorArrow()})        
	
	DBSelectArea(_cAlias)
	(_cAlias)->(DBGoTop())        
	             	
	//Armazena o numero de registros encontrados.
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	
	//Efetua o grupamento dos dados dos vendedores.
	While (_cAlias)->( !Eof() )
	
		IncProc("Processando dados das comissoes do vendedor, favor aguardar...")
		
		_nPosicao := aScan( _aVendedor , {|k| k[1] == (_cAlias)->CODVEND } )
		
		If _nPosicao == 0
		
			aAdd( _aVendedor , {	(_cAlias)->CODVEND		,;
									(_cAlias)->NOMEVEND		,;
									(_cAlias)->DEDUCAO		,;
									(_cAlias)->COMISSAO		,;
									(_cAlias)->VLRRECEB		})
			
		Else
		
			_aVendedor[_nPosicao,4] += (_cAlias)->COMISSAO
			_aVendedor[_nPosicao,5] += (_cAlias)->VLRRECEB
		
		EndIf
		
	(_cAlias)->( DBSkip() )
    EndDo

DBSelectArea(_cAlias)
(_cAlias)->( DBCloseArea() )

//Imprime os dados das comissoes dos vendedores.
If Len(_aVendedor) > 0                                                                       	

	//Ordena os dados por descricao dos vendedores.
	aSort( _aVendedor ,,, {|x, y| x[2] < y[2] } )

	//Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao
    _oPrint:EndPage()					// Finaliza a Pagina.
	_oPrint:StartPage()					// Inicia uma nova Pagina
	
	_nPagina++
	ROMS029CAB( .T. )//Chama cabecalho
    
    ROMS029PPG('Representantes') 

	For x := 1 To Len( _aVendedor )
	
		_nLinha += _nSpcLin
		_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)
		
		ROMS029QPG(0,.T.,.T.,"ROMS029BOX()","ROMS029CDR('Representantes')")  
	  	
		_aValALM		:= ROMS029CAD( _aVendedor[x,1] )
	  	
		IIf( _aValALM[04] > 0 , _aVendedor[x,4] += _aValALM[04] , Nil )
	  	
		_aImpostos	:= U_C_IRRF_INSS(_aVendedor[x,3],_aVendedor[x,4])
		_nValBnf	:= ROMS029CBN( _aVendedor[x,1] )
	  	
		ROMS029PRD( _aVendedor[x,2] , _aVendedor[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aVendedor[x,5] , _nValBnf )
		
		//Seta variaveis de controle dos totalizadores
		_nTotVComi += _aVendedor[x,4]
		_nTotVINSS += _aImpostos[1,1]
		_nTotVIRRF += _aImpostos[1,2]
		_nTotVBase += _aVendedor[x,5]
		_nTotVBoni += _nValBnf
	
	Next x
	
	_nLinha += _nSpcLin
	
	_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )  
	
	ROMS029QPG( 0 , .T. , .T. , "ROMS029BOX()" , "ROMS029CDR('Representantes')" )
		
	//Imprime o totalizador dos vendedores.
	ROMS029TOT( 'Total' , _nTotVComi , _nTotVINSS , _nTotVIRRF , _nTotVBase , _nTotVBoni )
	
	_nLinha+=_nSpcLin
	ROMS029BOX()  

EndIf            

	//Chama a rotina para selecao dos registros da comissao gerada para os vendedores
	MsgRun("Aguarde....Filrando comissão dos coordenadores.",,{||CursorWait(),ROMS029QRY(_cAliasVend,2),CursorArrow()})        
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())        
	             	
	//Armazena o numero de registros encontrados.
	COUNT TO _nCountRec 
	
	ProcRegua(_nCountRec)
	
	DBSelectArea(_cAliasVend)
	(_cAliasVend)->(DBGoTop())       
	               	
	//Efetua o grupamento dos dados dos vendedores
	While (_cAliasVend)->(!Eof()) 
		
			IncProc("Processando dados das comissoes do coordenador, favor aguardar...")
			
			_nPosicao:= aScan(_aCoordena,{|k| k[1] == (_cAliasVend)->CODCOORD})  
			
			If _nPosicao == 0
			      
				aAdd(_aCoordena,{(_cAliasVend)->CODCOORD,(_cAliasVend)->NOMECOORD,(_cAliasVend)->DEDUCAO,(_cAliasVend)->COMISSAO,(_cAliasVend)->VLRRECEB})
				
					Else
					
						_aCoordena[_nPosicao,4] += (_cAliasVend)->COMISSAO 
						_aCoordena[_nPosicao,5] += (_cAliasVend)->VLRRECEB
			
			EndIf 
					
	(_cAliasVend)->(DBSkip())	
    EndDo                          

DBSelectArea(_cAliasVend)
(_cAliasVend)->(DBCloseArea())     

//Verifica a necessidade de quebra de pagina.
_nLinha+=_nSpcLin	

ROMS029QPG(0,.F.,.F.,"","")    

//Imprime os dados das comissoes dos vendedores.
If Len(_aCoordena) > 0  

	//Ordena os dados por descricao dos vendedores.
	aSort(_aCoordena,,,{|x, y| x[2] < y[2]})
  	//Imprime o cabecalho da primeira pagina, forca a quebra de pagina para esta impressao
    ROMS029PPG('Coordenadores') 

	For x:=1 to Len(_aCoordena)
	   	  			   	  
		_nLinha += _nSpcLin
		_oPrint:Line( _nLinha , _nColIni , _nLinha , _nColFim )
		
		ROMS029QPG(0,.T.,.T.,"ROMS029BOX()","ROMS029CDR('Coordenadores')")  
		
		_aValALM	:= ROMS029CAD( _aCoordena[x,1] )
		
		IIf( _aValALM[04] > 0 , _aCoordena[x,4] += _aValALM[04] , Nil )
		
		_aImpostos	:= U_C_IRRF_INSS( _aCoordena[x,3] , _aCoordena[x,4] )
		_nValBnf	:= ROMS029BNF( _aCoordena[x,1] )
	  	
		ROMS029PRD( _aCoordena[x,2] , _aCoordena[x,4] , _aImpostos[1,1] , _aImpostos[1,2] , _aCoordena[x,5] , _nValBnf )
	  	
		//Seta variaveis de controle dos totalizadores.
		_nTotCComi += _aCoordena[x,4]
		_nTotCINSS += _aImpostos[1,1]
		_nTotCIRRF += _aImpostos[1,2]
		_nTotCBase += _aCoordena[x,5]
		_nTotCBoni += _nValBnf
	
	Next x
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
	  
	ROMS029QPG(0,.T.,.T.,"ROMS029BOX()","ROMS029CDR('Coordenadores')")     

	//Imprime o totalizador dos vendedores.
	ROMS029TOT('Total',_nTotCComi,_nTotCINSS,_nTotCIRRF,_nTotCBase,_nTotCBoni)
	
	_nLinha+=_nSpcLin
	ROMS029BOX()

EndIf

//Realiza a impressao do total gera do relatorio.
If Len(_aVendedor) > 0 .Or. Len(_aCoordena) > 0

	_nLinha+=_nSpcLin
	ROMS029QPG(0,.F.,.F.,"","")  
	
	ROMS029PPG('Somatório geral da comissão')      
	
	_nLinha+=_nSpcLin	     
	_oPrint:Line(_nLinha,_nColIni,_nLinha,_nColFim)  
		  
	ROMS029QPG(0,.T.,.T.,"ROMS029BOX()","ROMS029CDR('Somatório geral da comissão')")  
	
	_nVlrComis	:= _nTotVComi + _nTotCComi
	_nINSS		:= _nTotVINSS + _nTotCINSS     
	_nIRRF		:= _nTotVIRRF + _nTotCIRRF   
	_nVlrBase	:= _nTotVBase + _nTotCBase
	_nVlrBoni	:= _nTotVBoni + _nTotCBoni
	
	ROMS029PRD('Total Geral',_nVlrComis,_nINSS,_nIRRF,_nVlrBase,_nVlrBoni)
	
	_nLinha+=_nSpcLin
	ROMS029BOX()  

EndIf

Return 

/*
===============================================================================================================================
Programa--------: ROMS029CAD
Autor-----------: Fabiano Dias
Data da Criacao-: 30/03/2011
Descrição-------: Rotina que retorna os valores de matéria gorda para os cálculos adicionais
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029CAD( _cCodVen )

Local _cDtRef		:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _aRet			:= {0,0,0,0}

Default _cCodVen	:= ' '

DBSelectArea('ZC1')
ZC1->( DBSetOrder(1) )
If ZC1->( DBSeek( xFilial('ZC1') + _cCodVen + _cDtRef ) )
	
	_aRet[01] := ZC1->ZC1_VALLMG
	_aRet[02] := ZC1->ZC1_PERLMG
	_aRet[03] := Round( ( ZC1->ZC1_VALCAD / ZC1->ZC1_VALLMG ) * 100 , 2 )
	_aRet[04] := ZC1->ZC1_VALCAD
	
EndIf

Return( _aRet )

/*
===============================================================================================================================
Programa----------: ROMS029CBN
Autor-------------: Fabiano Dias
Data da Criacao---: 01/04/2011
Descrição---------: Funcao usada para verificar os valores de comissão sobre bonificação
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS029CBN( _cCodVen )

Local _cDtRef  := SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _nRet    := 0

DBSelectArea('ZC6')
ZC6->( DBSetOrder(1) )
If ZC6->( DBSeek( xFilial('ZC6') + _cCodVen + _cDtRef ) )
	
	_nRet := Round( ZC6->ZC6_VALLIQ * ( ZC6->ZC6_PERCOM / 100 ) , 2 )
	
EndIf

Return( _nRet )

/*
===============================================================================================================================
Programa--------: ROMS029BNF
Autor-----------: Alexandre Villar
Data da Criacao-: 2014
Descrição-------: Funcao que retorna os dados de cálculos de bonificações
Parametros------: _cCodCor - Código do coordenador que está sendo apurado
Retorno---------: _aRet    - Array com dados das bonificações
===============================================================================================================================
*/
Static Function ROMS029BNF( _cCodCor )

Local _cAlias		:= GetNextAlias()
Local _cQuery		:= ""
Local _cDtRef		:= SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 )
Local _nRet			:= 0

Default _cCodCor	:= ' '

_cQuery := " SELECT "
_cQuery += "     Round( SUM( ZC7.ZC7_VALLIQ * ( ZAE.ZAE_COMIS1 / 100 ) ) , 2 ) AS VALCMS "
_cQuery += " FROM "+ RetSqlName('ZC7') +" ZC7 "
_cQuery += " INNER JOIN "+ RetSqlName('SA3') +" SA3 "
_cQuery += " ON "
_cQuery += "     SA3.A3_COD     = SubStr( ZC7.ZC7_CHAVE , 1 , 6 ) "
_cQuery += " INNER JOIN "+ RetSqlName('ZAE') +" ZAE "
_cQuery += " ON "
_cQuery += "     ZAE.ZAE_VEND   = SA3.A3_COD "
_cQuery += " AND ZAE.ZAE_COMIS1 > 0 "
_cQuery += " AND ZAE.ZAE_PROD   = ZC7.ZC7_CODPRD "
_cQuery += " WHERE "
_cQuery += "     ZC7.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
_cQuery += " AND ZC7.ZC7_ITEM   = '01' "
_cQuery += " AND SubStr(ZC7.ZC7_CHAVE,1,6) = '"+ _cCodCor +"' "
_cQuery += " AND SubStr(ZC7.ZC7_CHAVE,7,6) = '"+ _cDtRef  +"' "

_cQuery += " UNION ALL "

_cQuery += " SELECT "
_cQuery += "     Round( SUM( ZC7.ZC7_VALLIQ * ( ZAE.ZAE_COMIS2 / 100 ) ) , 2 ) AS VALCMS "
_cQuery += " FROM "+ RetSqlName('ZC7') +" ZC7 "
_cQuery += " INNER JOIN "+ RetSqlName('SA3') +" SA3 "
_cQuery += " ON "
_cQuery += "     SA3.A3_COD     = SubStr( ZC7.ZC7_CHAVE , 1 , 6 ) "
_cQuery += " INNER JOIN "+ RetSqlName('ZAE') +" ZAE "
_cQuery += " ON "
_cQuery += "     ZAE.ZAE_VEND   = SA3.A3_COD "
_cQuery += " AND ZAE.ZAE_COMIS2 > 0 "
_cQuery += " AND ZAE.ZAE_PROD   = ZC7.ZC7_CODPRD "
_cQuery += " WHERE "
_cQuery += "     ZC7.D_E_L_E_T_ = ' ' "
_cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZAE.ZAE_GRPVEN = ' ' "
_cQuery += " AND ZAE.ZAE_CLI    = ' ' "
_cQuery += " AND ZAE.ZAE_LOJA   = ' ' "
_cQuery += " AND ZAE.ZAE_CODSUP = '"+ _cCodCor +"' "
_cQuery += " AND SubStr(ZC7.ZC7_CHAVE,7,6) = '"+ _cDtRef +"' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

While (_cAlias)->(!Eof())

	_nRet += IIf( ValType( (_cAlias)->VALCMS ) == 'N' , (_cAlias)->VALCMS , 0 )

(_cAlias)->( DBSkip() )
EndDo

Return( _nRet )
