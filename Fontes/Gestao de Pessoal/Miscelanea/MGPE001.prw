/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |20/01/2015| Chamado 8635. Verificação para buscar apenas as cargas 'Faturadas' no período, pois existem casos 
              |          | onde as mesmas são geradas em um período e faturadas em outro.
Alexandre V.  |08/06/2015| Chamado 10463. Atualização da rotina para correção da chamada da tabela na Query.
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE001
Autor-------------: Fabiano Dias
Data da Criacao---: 10/09/2010
Descrição---------: Geração do arquivo TXT com o somatório total por Autônomo
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE001()

Local _cPerg := "MGPE001"

Pergunte( _cPerg )

//====================================================================================================
// Montagem da tela de processamento
//====================================================================================================
If MessageBox(	'Essa Rotina tem o objetivo de processar a geração do arquivo texto (TXT) com a relação de Autônomos e valores Totais do período '			+;
				'conforme os parâmetros definidos pelo usuário.'																					+ CRLF	+;
				'O Layout do arquivo trará o código do autônomo e o valor pago, independente de Filial. Confirma a geração do arquivo?'						,;
				'Confirmação!' , 04 ) == 6
	
	Processa( {|| MGPE001TXT() } , 'Aguarde!' , 'Processando os dados...' )
	
Else
	Aviso( 'Atenção!' , 'Operação cancelada pelo usuário!' , {'Fechar'} )
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE001TXT
Autor-------------: Fabiano Dias
Data da Criacao---: 10/09/2010
Descrição---------: Geração do arquivo TXT com o somatório total por Autônomo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE001TXT()

Local _cAlias		:= GetNextAlias()
Local _cQuery		:= ''
Local _cArqTxt		:= ''
Local _cLin			:= ''
Local _nHdl			:= 0
Local _nCont		:= 0

//====================================================================================================
// Validacoes dos Parametros - é obrigatório informar a data inicial e final para gerar o arquivo
//====================================================================================================
If Empty( MV_PAR01 ) .Or. Empty( MV_PAR02 ) .Or. Empty( MV_PAR05 ) 

	MessageBox( 'Os parâmetros obrigatórios não foram informados! Verifique os parâmetros para processar corretamente a rotina.' , 'Atencao!' , 16 )
	Return

EndIf

_cArqTxt	:= AllTrim( MV_PAR05 )
_nHdl		:= FCreate( _cArqTxt )

//====================================================================================================
// Processa a criação do arquivo físico
//====================================================================================================
If _nHdl == -1
	MessageBox( 'O arquivo: '+ _cArqTxt +' não foi criado! Verifique os parâmetros e o acesso ao diretório de destino.' , 'Atencao!' , 16 )
	Return
EndIf     

//====================================================================================================
// Seleciona os produtores donos de tanque e seu volume de Leite no período
//====================================================================================================
_cQuery := " SELECT "
_cQuery += "     AUTONOMO , "
_cQuery += "     SUM( TOTAL ) AS TOTAL "
_cQuery += " FROM ( "

_cQuery += "        SELECT
_cQuery += "            ZZ2.ZZ2_AUTONO AS AUTONOMO,
_cQuery += "            COALESCE( SUM( ZZ2.ZZ2_TOTAL ) , 0 ) AS TOTAL
_cQuery += "        FROM "+ RetSqlName('ZZ2') +" ZZ2 "
_cQuery += "        WHERE "
_cQuery += "            ZZ2.D_E_L_E_T_ =  ' ' "
_cQuery += "        AND ZZ2.ZZ2_CARGA  <> ' ' "
_cQuery += "        AND ZZ2.ZZ2_AUTONO BETWEEN '"+ MV_PAR03       +"' AND '"+ MV_PAR04       +"' "
_cQuery += "        AND EXISTS ( SELECT 1 FROM "+ RetSqlName('SF2') +" SF2 "
_cQuery += "                     WHERE "
_cQuery += "                         SF2.D_E_L_E_T_ = ' ' "
_cQuery += "                     AND SF2.F2_EMISSAO BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"' "
_cQuery += "                     AND SF2.F2_FILIAL  = ZZ2.ZZ2_FILIAL "
_cQuery += "                     AND SF2.F2_CARGA   = ZZ2.ZZ2_CARGA ) "
_cQuery += "        GROUP BY ZZ2.ZZ2_AUTONO "

_cQuery += "        UNION ALL "

_cQuery += "        SELECT "
_cQuery += "            ZZ2.ZZ2_AUTONO AS AUTONOMO , "
_cQuery += "            COALESCE( SUM( ZZ2.ZZ2_TOTAL ) , 0 ) AS TOTAL "
_cQuery += "        FROM "+ RetSqlName('ZZ2') +" ZZ2 "
_cQuery += "        INNER JOIN "+ RetSqlName('SA2') +" SA2 "
_cQuery += "        ON
_cQuery += "          ( SA2.A2_I_AUTAV = ZZ2.ZZ2_AUTONO
_cQuery += "         OR SA2.A2_I_AUT   = ZZ2.ZZ2_AUTONO )
_cQuery += "        AND SA2.D_E_L_E_T_ = ' '
_cQuery += "        INNER JOIN "+ RetSqlName('SE2') +" SE2 "
_cQuery += "        ON "
_cQuery += "            SE2.E2_FILIAL  = ZZ2.ZZ2_FILIAL "
_cQuery += "        AND SE2.E2_NUM     = ZZ2.ZZ2_RECIBO "
_cQuery += "        AND SE2.E2_PREFIXO = 'AUT' "
_cQuery += "        AND SE2.E2_TIPO    = 'RPA' "
_cQuery += "        AND SE2.E2_FORNECE = SA2.A2_COD "
_cQuery += "        AND SE2.E2_LOJA    = SA2.A2_LOJA "
_cQuery += "        AND SE2.D_E_L_E_T_ = ' ' "
_cQuery += "        WHERE
_cQuery += "            ZZ2.D_E_L_E_T_ = ' '
_cQuery += "        AND ZZ2.ZZ2_CARGA  = ' '
_cQuery += "        AND ZZ2.ZZ2_AUTONO BETWEEN '"+ MV_PAR03       +"' AND '"+ MV_PAR04       +"' "
_cQuery += "        AND SE2.E2_EMISSAO BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"' "
_cQuery += "        GROUP BY ZZ2_AUTONO "

_cQuery += " ) QRY "
_cQuery += " GROUP BY AUTONOMO "
_cQuery += " ORDER BY AUTONOMO "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .T. )

ProcRegua(0)

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	_nCont++
	IncProc( "Processando registros... ["+ StrZero( _nCont , 6 ) +"]" )
	
	_cLin 	:= PadR( (_cAlias)->AUTONOMO , 6 ) +" "								// Codigo do Autonomo
	_cLin 	+= PadL( AllTrim( Str( (_cAlias)->TOTAL , 17 , 2 ) ) , 17 , "0" )	// Valor total
	_cLin	+= CRLF
	
	FWrite( _nHdl , _cLin )
    
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

//====================================================================================================
// Libera o arquivo gerado
//====================================================================================================
FClose( _nHdl )

Aviso( 'Concluído!' , 'Arquivo gerado com sucesso em:' +CRLF+ _cArqTxt , {'Ok'} , 2 )

Return
