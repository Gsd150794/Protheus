/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |27/08/2024| Chamado 46903 - Adição de Campos de VAlores de Abatimento, Descovnto e verba
Igor Melgaço  |06/09/2024| Chamado 48444 - Correção de error.log
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
=========================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Antonio Ramos    -  Igor Melgaço     - 28/10/2024 - 28/10/2024 - 48925   - Ajuste para correção de error log e exibição de msg pós exportar para excel
Antonio Ramos    -  Igor Melgaço     - 12/06/2025 - 20/06/2025 - 50837   - Ajustes para correção de error log e exibição correta de colunas de acordo com o cabeçalho
=========================================================================================================================================================
*/

#Include "TOTVS.ch"      

/*
===============================================================================================================================
Programa--------: ROMS025
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
Descrição-------: Relatorio para demonstrar os valores de comissao gerados na baixa do titulo
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/  
User Function ROMS025()  
Local oProc As Object
Local _aHeader As Array
Local _aData As Array
Local _aLinha As Array
Local _nCol As Numeric
Local _nLin As Numeric
Local _nCampos As Numeric
Local _aHeaderD As Array

Private _aDados As Array
Private cPerg  As Character
Private oPrint	As Object
Private _aDadosExcel As Array
Private _aItalac_F3 As Array
Private _lPergunte As Logical
Private _aTitulo As Array

oProc     := {}
_aHeader  := {}
_aHeaderD := {}
_aData    := {}
_aLinha   := {}
_nCol     := 0
_nLin     := 0
_nCampos  := 0

_aDados       := {}
cPerg         := "ROMS025N"
oPrint		  := Nil
_aDadosExcel  := {}
_aItalac_F3   := {} 
_lPergunte    := .T.  
_aTitulo      := {}

aAdd(_aDadosExcel,"G-Gerente")
aAdd(_aDadosExcel,"C-Coordenador")
aAdd(_aDadosExcel,"S-Supervisor")
aAdd(_aDadosExcel,"V-Vendedor")
aAdd(_aDadosExcel,"N-Gerente Nacional") 
               //        1           2             3             4               5            6                                           7         8        9  10  11  12
aAdd(_aItalac_F3,{"MV_PAR07",/*_cTabela*/ ,/*_nCpoChave*/ , /*_nCpoDesc*/ , /*_bCondTab*/ , "Dados a Serem Exibidos no Relatório Excel" , 1 , _aDadosExcel , 5,   ,   ,   })

While .T.
   _lPergunte := Pergunte( cPerg , .T.)
   
   If ! _lPergunte
      If U_ITMsg("Deseja realmente encerrar a emissão deste relatório?","Atenção" , , ,2, 2) 
         Exit
      EndIf
   Else
      Exit
   EndIf
EndDo

If _lPergunte 
   If MV_PAR08 == 1
      FWMsgRun( ,{|oproc| ROMS025E(oproc) } , "Aguarde...", " Processando o relatorio..." ) // Baixa Vendedor
   ElseIf MV_PAR08 == 2
      FWMsgRun( ,{|oproc| ROMS025F(oproc) } , "Aguarde...", " Processando o relatorio..." ) // Baixa Detalhado
   ElseIf MV_PAR08 == 3
      FWMsgRun( ,{|oproc| ROMS025H(oproc) } , "Aguarde...", " Processando o relatorio..." ) // Previsão de Comissão
   EndIf
   
   If MV_PAR08 == 2 // Gera os títulos para o relatório baixa detalhado.
      ROMS025D() 
   Else             // Gera os títulos para o relatório baixa vendedor e Previsão de comissão.
      ROMS025C()
   EndIf 
      
   _aHeader := AClone(_aTitulo)

   If Len(_aDados) > 0
	   If Len(_aDados[1]) < Len(_aHeader)
	      _nCampos := Len(_aDados[1]) 
	   Else
	      _nCampos := Len(_aHeader) 
	   EndIf

	   For _nLin := 1 to Len(_aDados)
	      _aLinha := {}
	      For _nCol := 1 to _nCampos
	        aAdd(_aLinha,_aDados[_nLin,_nCol])
	      Next
	      aAdd(_aData,_aLinha)
	   Next
      If Len(_aHeader) > _nCampos
         For _nLin := 1 to _nCampos
            aAdd(_aHeaderD,_aHeader[_nLin])
         Next
      Else
         _aHeaderD := aClone(_aHeader)
      EndIf
	   U_ITListBox( 'Fechamento de comissão - Analítico por Representante' ,_aHeaderD , _aData , .T. , 1 )
   Else
	   U_ITMsg("Não foram encontrados dados","Atenção",,1)
   EndIf
	
EndIf

Return
/*
===============================================================================================================================
Programa--------: ROMS025QRY
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
Descrição-------: Funcao de monta e realiza as consultas de dados do relatório
Parametros------: _cAlias - Alias que será instanciado pela consulta
----------------: _nOpcao - Opção de consulta que será processada
                  oproc   - Objeto FWMsgRun 
Retorno---------: Nenhum
===============================================================================================================================
*/                                    
Static Function ROMS025QRY( _cAlias As Character, _nOpcao As Numeric, oProc As Object )

Local _cFiltro As Character
Local _cFiltEmis As Character
Local _cFilVeCoo As Character
Local _cFilCooVe As Character
Local _cFilTRONC As Character
Local _cfiltrobon As Character
Local _cFilSemBaixa As Character
Local _cFechComis As Character
Local _cAnoMesFech As Character

_cFiltro		  := "%"
_cFiltEmis    := "%"
_cFilVeCoo	  := "%"
_cFilCooVe	  := "%"
_cFilTRONC	  := "" 
_cfiltrobon   := ""
_cFilSemBaixa := "" 
_cFechComis   := GetMv("IT_COMFECHA",.F., Space(6))
_cAnoMesFech  := ""

//====================================================================================================
// Filtra geracao da comissao
//====================================================================================================
If !Empty( MV_PAR01 )
   If MV_PAR08 <> 3 // Não é a opção Previsão de Comissão
	  _cFiltro	+= " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	  _cFiltEmis	+= " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	  _cFilCooVe	+= " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	  _cFiltrobon	+= " AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
   Else // É a opção Previsão de Comissão
	  If Empty(MV_PAR09)
	     _cFiltro	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFiltEmis	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFilCooVe	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFiltrobon += " AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
         //-----------------------------------------------------------------------------------------------------------------------//
	     _cFilSemBaixa += " AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	  Else
	     _cFiltro	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) >= '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFiltEmis	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) >= '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFilCooVe	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) >= '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFiltrobon += " AND SubStr( F2_EMISSAO , 1 , 6 ) >= '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
		 
		 _cFiltro	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) <= '"+ SubStr( MV_PAR09 , 3 , 4 ) + SubStr( MV_PAR09 , 1 , 2 ) +"'"
	     _cFiltEmis	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) <= '"+ SubStr( MV_PAR09 , 3 , 4 ) + SubStr( MV_PAR09 , 1 , 2 ) +"'"
	     _cFilCooVe	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) <= '"+ SubStr( MV_PAR09 , 3 , 4 ) + SubStr( MV_PAR09 , 1 , 2 ) +"'"
	     _cFiltrobon += " AND SubStr( F2_EMISSAO , 1 , 6 ) <= '"+ SubStr( MV_PAR09 , 3 , 4 ) + SubStr( MV_PAR09 , 1 , 2 ) +"'"
	     //-----------------------------------------------------------------------------------------------------------------------//
	     _cFilSemBaixa += " AND SubStr( F2_EMISSAO , 1 , 6 ) >= '"+ SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) +"'"
	     _cFilSemBaixa += " AND SubStr( F2_EMISSAO , 1 , 6 ) <= '"+ SubStr( MV_PAR09 , 3 , 4 ) + SubStr( MV_PAR09 , 1 , 2 ) +"'"
	  EndIf
	  //==========================================================================================
	  // Para as query que não são previsão considerar o período que a comissão não foi baixada.
	  //==========================================================================================
	  If ! Empty(_cFechComis) 
         _cAnoMesFech := SubStr(_cFechComis,4,4) + SubStr(_cFechComis,1,2) 
		 _cFiltro	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) >= '" + _cAnoMesFech + "'"
	     _cFiltEmis	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) >= '" + _cAnoMesFech + "'"
	     _cFilCooVe	 += " AND SubStr( E3_EMISSAO , 1 , 6 ) >= '" + _cAnoMesFech + "'"
	     _cFiltrobon += " AND SubStr( F2_EMISSAO , 1 , 6 ) >= '" + _cAnoMesFech + "'"
      EndIf
	  
   EndIf	
EndIf

//====================================================================================================
// Gerente Nacional  
//====================================================================================================
If !Empty( MV_PAR02 )
   _cFiltro	+= " AND F2.F2_VEND5 IN "+ FormatIn( MV_PAR02 , ";" )
   _cFilVeCoo	+= " AND F2.F2_VEND5 IN "+ FormatIn( MV_PAR02 , ";" )
   _cFilCooVe	+= " AND A3.A3_I_GERNC IN "+ FormatIn( MV_PAR02 , ";" )
   _cFiltroBON	+= " AND F2_VEND5 IN "+ FormatIn( MV_PAR02 , ";" )
   _cFilSemBaixa += " AND F2_VEND5 IN "+ FormatIn( MV_PAR02 , ";" )
EndIf

//====================================================================================================
// Gerente
//====================================================================================================
If !Empty( MV_PAR03 )
    
	_cFiltro	+= " AND F2.F2_VEND3 IN "+ FormatIn( MV_PAR03 , ";" )
	_cFilVeCoo	+= " AND F2.F2_VEND3 IN "+ FormatIn( MV_PAR03 , ";" )
	_cFilCooVe	+= " AND A3.A3_GEREN IN "+ FormatIn( MV_PAR03 , ";" )
	//_cFiltronc	+= " OR E3.E3_VEND IN "+ FormatIn( MV_PAR03 , ";" )  
	_cFiltroBON	+= " AND F2_VEND3 IN "+ FormatIn( MV_PAR03 , ";" )
    _cFilSemBaixa += " AND F2_VEND3 IN "+ FormatIn( MV_PAR03 , ";" )
    
EndIf

//====================================================================================================
// Coordenador
//====================================================================================================
If !Empty( MV_PAR04 )
    
	_cFiltro	+= " AND F2.F2_VEND2 IN "+ FormatIn( MV_PAR04 , ";" )
	_cFilVeCoo	+= " AND F2.F2_VEND2 IN "+ FormatIn( MV_PAR04 , ";" )
	_cFilCooVe	+= " AND A3.A3_SUPER IN "+ FormatIn( MV_PAR04 , ";" )
	_cFiltronc	+= " OR E3.E3_VEND IN "+ FormatIn( MV_PAR04 , ";" )
	_cFiltroBON	+= " AND F2_VEND2 IN "+ FormatIn( MV_PAR04 , ";" )
    _cFilSemBaixa += " AND F2_VEND2 IN "+ FormatIn( MV_PAR04 , ";" )

EndIf

//====================================================================================================
// Supervisor
//====================================================================================================
If !Empty( MV_PAR05 )
    
	_cFiltro	+= " AND F2.F2_VEND4 IN "+ FormatIn( MV_PAR05 , ";" )
	_cFilVeCoo	+= " AND F2.F2_VEND4 IN "+ FormatIn( MV_PAR05 , ";" )
	_cFilCooVe	+= " AND A3.A3_I_SUPE IN "+ FormatIn( MV_PAR05 , ";" )
	_cFiltronc	+= " OR E3.E3_VEND IN "+ FormatIn( MV_PAR05 , ";" )
	_cFiltroBON	+= " AND F2_VEND4 IN "+ FormatIn( MV_PAR05 , ";" )
    _cFilSemBaixa += " AND F2_VEND4 IN "+ FormatIn( MV_PAR05 , ";" )

EndIf


//====================================================================================================
// Vendedor
//====================================================================================================
If !Empty( MV_PAR06 )
    
	_cFiltro    += " AND F2.F2_VEND1 IN "+ FormatIn( MV_PAR06 , ";" )
	_cFilVeCoo  += " AND F2.F2_VEND1 IN "+ FormatIn( MV_PAR06 , ";" )
	_cFilCooVe  += " AND A3.A3_COD   IN "+ FormatIn( MV_PAR06 , ";" )
	_cFiltronc	+= " OR E3.E3_VEND IN "+ FormatIn( MV_PAR06 , ";" )
	_cFiltroBON += " AND F2_VEND1 IN "+ FormatIn( MV_PAR06 , ";" )
    _cFilSemBaixa += " AND F2_VEND1 IN "+ FormatIn( MV_PAR06 , ";" )

EndIf

_cFiltro	+= "%"
_cFiltEmis	+= "%"
_cFilVeCoo	+= "%"
_cFilCooVe	+= "%"

If !Empty(_cFiltronc) .And. AllTrim(_cFiltronc) <> "%"
   _cFiltronc := "% AND (" + SubStr(_cFiltronc,4,Len(_cFiltronc)) + ") %" 
ElseIf Empty(_cFiltronc) .Or.  AllTrim(_cFiltronc) == "%"
   _cFiltronc := "% %" 
EndIf

//_cFilTRONC	+= "%" 

Do Case

	//====================================================================================================
	// Seleciona dados para o relatorio do tipo analitico, para as comissoes de credito e debito
	//====================================================================================================
	Case _nOpcao == 1
	       
		BeginSql alias _cAlias
		
		SELECT
			E3.E3_FILIAL	AS FILIAL,
			E1.E1_EMISSAO	AS DTEMISSAO,
			E3.E3_EMISSAO	AS DTBAIXA,
			E3.E3_TIPO		AS TIPO,
			E3.E3_NUM		AS NUMERO,
			E3.E3_SERIE		AS SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	AS PARCELA,
			E3.E3_CODCLI	AS CODCLI,
			E3.E3_LOJA		AS LOJA,
			E1.E1_NOMCLI	AS NOMCLI,
			E1.E1_VALOR		AS VLRTITULO,
			E3.E3_BASE		AS BASECOMIS,
			E3.E3_COMIS		AS COMISSAO,
			E3.E3_VEND		AS CODVEND,
			A3.A3_NOME		AS NOMEVEND,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX     = 'CMP'
				AND E5.E5_RECPAG    = 'R' ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
												FROM %Table:SE5% E5
												WHERE
													E1.E1_FILIAL    = E5.E5_FILIAL
												AND E1.E1_PREFIXO   = E5.E5_PREFIXO
												AND E1.E1_TIPO      = E5.E5_TIPO
												AND E1.E1_NUM       = E5.E5_NUMERO
												AND E1.E1_PARCELA   = E5.E5_PARCELA
												AND E1.E1_CLIENTE   = E5.E5_CLIENTE
												AND E1.E1_LOJA      = E5.E5_LOJA
												AND E5.D_E_L_E_T_   = ' '
												AND E5.E5_TIPO     IN ('NF ','ICM')
												AND E5.E5_TIPODOC   = 'ES'
												AND E5.E5_SITUACA  <> 'C'
												AND E5.E5_MOTBX     = 'CMP'
												AND E5.E5_RECPAG    = 'P' ) COMPENSACAO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' ' 
				AND E5.E5_SITUACA  <> 'C'
				AND ( (		E5.E5_TIPO     = 'NF '
						AND E5.E5_TIPODOC <> 'ES'
						AND E5.E5_MOTBX   IN ('DCT','VBC')
						AND E5.E5_NATUREZ IN ('231002','231017','231019','231013','231014','231015','231016','233004','111001')
						AND E5.E5_RECPAG   = 'R')
					OR (	E5_TIPODOC     = 'DC' ) ) ) DESCONTO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '   
				AND E5.E5_TIPODOC  <> 'ES'   
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX    IN ('NOR','DAC','FAT','LQ ')
				AND E5.E5_RECPAG    = 'R'
				AND E5.E5_DATA      < E3.E3_EMISSAO ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
															FROM %Table:SE5% E5
															WHERE
																E1.E1_FILIAL        = E5.E5_FILIAL
															AND E1.E1_PREFIXO   = E5.E5_PREFIXO
															AND E1.E1_TIPO      = E5.E5_TIPO
															AND E1.E1_NUM       = E5.E5_NUMERO
															AND E1.E1_PARCELA   = E5.E5_PARCELA
															AND E1.E1_CLIENTE   = E5.E5_CLIENTE
															AND E1.E1_LOJA      = E5.E5_LOJA
															AND E5.D_E_L_E_T_   = ' '
															AND E5.E5_TIPO      = 'NF '
															AND E5.E5_TIPODOC   = 'ES'
															AND E5.E5_SITUACA  <> 'C'
															AND E5.E5_MOTBX    IN ( 'NOR' , 'DAC' , 'FAT' , 'LQ ' )
															AND E5.E5_RECPAG    = 'P' ) BAIXASANT,
      		'C' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI,

         NVL((SELECT SUM(SE1_2.E1_VALOR) 
               FROM %Table:SE1% SE1_2 
               WHERE SE1_2.E1_FILIAL = E1.E1_FILIAL AND SE1_2.E1_NUM = E1.E1_NUM AND SE1_2.E1_PREFIXO='DCT' AND SE1_2.E1_CLIENTE = E1.E1_CLIENTE AND SE1_2.E1_LOJA = E1.E1_LOJA AND SE1_2.E1_PARCELA = E1.E1_PARCELA AND SE1_2.D_E_L_E_T_ =' '), 0) VALDCT, /*VALOR DESCONTO */
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE SE5.E5_FILORIG = E1.E1_FILIAL AND SE5.E5_NUMERO = E1.E1_NUM AND SE5.E5_PREFIXO='DCT' AND SE5.E5_CLIFOR = E1.E1_CLIENTE AND SE5.E5_LOJA = E1.E1_LOJA AND SE5.E5_PARCELA = E1.E1_PARCELA AND SE5.D_E_L_E_T_ =' '), 0) SE5DCT, /*VALOR DESCONTO COMPENSADO*/
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE E1.E1_PREFIXO||E1.E1_NUM||E1.E1_TIPO||E1.E1_PARCELA||E1.E1_LOJA = SE5.E5_DOCUMEN AND SE5.E5_PREFIXO='VRB' AND SE5.D_E_L_E_T_ =' '), 0) SE5VRB, /*VALOR VERBA DESCONTADO */
         NVL((SELECT SUM(F2_ICMSRET) 
               FROM %Table:SF2% SF2 
               WHERE SF2.F2_FILIAL = E1.E1_FILIAL AND SF2.F2_DOC = E1.E1_NUM AND SF2.F2_SERIE = E1.E1_PREFIXO AND SF2.D_E_L_E_T_ =' '),0) VALST /*VALOR ICM ST */
         		
      FROM %Table:SE3% E3
		
		JOIN %Table:SE1% E1 
		ON
			E1.E1_FILIAL  = E3.E3_FILIAL
		AND E1.E1_TIPO    = E3.E3_TIPO
		AND E1.E1_PREFIXO = E3.E3_PREFIXO
		AND E1.E1_NUM     = E3.E3_NUM  
		AND E1.E1_SERIE   = E3.E3_SERIE
		AND E1.E1_PARCELA = E3.E3_PARCELA
		AND E1.E1_CLIENTE = E3.E3_CODCLI
		AND E1.E1_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SF2% F2
		ON
			F2.F2_FILIAL  = E3.E3_FILIAL
		AND F2.F2_DOC     = E3.E3_NUM
		AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
		AND F2.F2_CLIENTE = E3.E3_CODCLI
		AND F2.F2_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SA3% A3 ON A3.A3_COD = E3.E3_VEND
		
		WHERE
			E3.D_E_L_E_T_ = ' '
		AND E1.D_E_L_E_T_ = ' '
		AND F2.D_E_L_E_T_ = ' '
		AND A3.D_E_L_E_T_ = ' '
		AND E3.E3_COMIS   > 0
		AND E1.E1_ORIGEM NOT IN ( 'FINA460' , 'FINA280' )
		
		%exp:_cFiltro%
		
		UNION ALL
		
		SELECT
			E3.E3_FILIAL FILIAL,
			E1.E1_EMISSAO DTEMISSAO,
			E3.E3_EMISSAO DTBAIXA,
			E3.E3_TIPO TIPO,
			E3.E3_NUM NUMERO,
			E3.E3_SERIE		AS SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	AS PARCELA,
			E3.E3_CODCLI CODCLI,
			E3.E3_LOJA LOJA,
			E1.E1_NOMCLI NOMCLI,
			E1.E1_VALOR VLRTITULO,
			E3.E3_BASE BASECOMIS,
			E3.E3_COMIS COMISSAO,
			E3.E3_VEND CODVEND,
			A3.A3_NOME NOMEVEND,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX     = 'CMP'
				AND E5.E5_RECPAG    = 'R' ) - (	SELECT COALESCE(SUM(E5.E5_VALOR),0)
												FROM %Table:SE5% E5
												WHERE
													E1.E1_FILIAL    = E5.E5_FILIAL
												AND E1.E1_PREFIXO   = E5.E5_PREFIXO
												AND E1.E1_TIPO      = E5.E5_TIPO
												AND E1.E1_NUM       = E5.E5_NUMERO
												AND E1.E1_PARCELA   = E5.E5_PARCELA
												AND E1.E1_CLIENTE   = E5.E5_CLIENTE
												AND E1.E1_LOJA      = E5.E5_LOJA
												AND E5.D_E_L_E_T_   = ' '
												AND E5.E5_TIPO     IN ('NF ','ICM')
												AND E5.E5_TIPODOC   = 'ES'
												AND E5.E5_SITUACA  <> 'C'
												AND E5.E5_MOTBX     = 'CMP'
												AND E5.E5_RECPAG    = 'P' ) COMPENSACAO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_SITUACA  <> 'C'
				AND ( (		E5.E5_TIPO      = 'NF '
						AND E5.E5_TIPODOC  <> 'ES'
						AND E5.E5_MOTBX    IN ('DCT','VBC')
						AND E5.E5_NATUREZ  IN ('231002','231017','231019','231013','231014','231015','231016','233004','111001')
						AND E5.E5_RECPAG    = 'R' )
					OR ( E5_TIPODOC = 'DC' ) ) ) DESCONTO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX    IN ( 'NOR' , 'DAC' , 'FAT' , 'LQ ' )
				AND E5.E5_RECPAG    = 'R'
				AND E5.E5_DATA      < E3.E3_EMISSAO ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
															FROM %Table:SE5% E5
															WHERE
																E1.E1_FILIAL    = E5.E5_FILIAL
															AND E1.E1_PREFIXO   = E5.E5_PREFIXO
															AND E1.E1_TIPO      = E5.E5_TIPO
															AND E1.E1_NUM       = E5.E5_NUMERO
															AND E1.E1_PARCELA   = E5.E5_PARCELA
															AND E1.E1_CLIENTE   = E5.E5_CLIENTE
															AND E1.E1_LOJA      = E5.E5_LOJA
															AND E5.D_E_L_E_T_   = ' '
															AND E5.E5_TIPO      = 'NF '
															AND E5.E5_TIPODOC   = 'ES'
															AND E5.E5_SITUACA  <> 'C'
															AND E5.E5_MOTBX    IN ( 'NOR' , 'DAC' , 'FAT' , 'LQ ' )
															AND E5.E5_RECPAG    = 'P' ) BAIXASANT,
			'C' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI,

         NVL((SELECT SUM(SE1_2.E1_VALOR) 
               FROM %Table:SE1% SE1_2 
               WHERE SE1_2.E1_FILIAL = E1.E1_FILIAL AND SE1_2.E1_NUM = E1.E1_NUM AND SE1_2.E1_PREFIXO='DCT' AND SE1_2.E1_CLIENTE = E1.E1_CLIENTE AND SE1_2.E1_LOJA = E1.E1_LOJA AND SE1_2.E1_PARCELA = E1.E1_PARCELA AND SE1_2.D_E_L_E_T_ =' '), 0) VALDCT, /*VALOR DESCONTO */
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE SE5.E5_FILORIG = E1.E1_FILIAL AND SE5.E5_NUMERO = E1.E1_NUM AND SE5.E5_PREFIXO='DCT' AND SE5.E5_CLIFOR = E1.E1_CLIENTE AND SE5.E5_LOJA = E1.E1_LOJA AND SE5.E5_PARCELA = E1.E1_PARCELA AND SE5.D_E_L_E_T_ =' '), 0) SE5DCT, /*VALOR DESCONTO COMPENSADO*/
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE E1.E1_PREFIXO||E1.E1_NUM||E1.E1_TIPO||E1.E1_PARCELA||E1.E1_LOJA = SE5.E5_DOCUMEN AND SE5.E5_PREFIXO='VRB' AND SE5.D_E_L_E_T_ =' '), 0) SE5VRB, /*VALOR VERBA DESCONTADO */
         NVL((SELECT SUM(F2_ICMSRET) 
               FROM %Table:SF2% SF2 
               WHERE SF2.F2_FILIAL = E1.E1_FILIAL AND SF2.F2_DOC = E1.E1_NUM AND SF2.F2_SERIE = E1.E1_PREFIXO AND SF2.D_E_L_E_T_ =' '),0) VALST /*VALOR ICM ST */
         		
		FROM %Table:SE3% E3
		
		JOIN %Table:SE1% E1
        ON
        	E1.E1_FILIAL  = E3.E3_FILIAL
        AND E1.E1_TIPO    = E3.E3_TIPO
        AND E1.E1_PREFIXO = E3.E3_PREFIXO
        AND E1.E1_NUM     = E3.E3_NUM
        AND E1.E1_SERIE   = E3.E3_SERIE
        AND E1.E1_PARCELA = E3.E3_PARCELA
        AND E1.E1_CLIENTE = E3.E3_CODCLI
        AND E1.E1_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SA3% A3 ON A3.A3_COD = E3.E3_VEND
		
		JOIN %Table:SF2% F2
		ON
			F2.F2_FILIAL  = E3.E3_FILIAL
		AND F2.F2_DOC     = E3.E3_NUM
		AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
		AND F2.F2_CLIENTE = E3.E3_CODCLI
		AND F2.F2_LOJA    = E3.E3_LOJA
		
		
		WHERE
			E3.D_E_L_E_T_ = ' '
	    AND E1.D_E_L_E_T_ = ' '
	    AND A3.D_E_L_E_T_ = ' '
	    AND E1.E1_NUM    IN (	SELECT SE1.E1_FATURA
								FROM %Table:SE1% SE1
								JOIN %Table:SF2% F2
								ON
									F2.F2_FILIAL   = SE1.E1_FILIAL
								AND F2.F2_DOC      = SE1.E1_NUM
								AND (F2.F2_SERIE    = SE1.E1_SERIE OR SE1.E1_SERIE = 'R')
								AND F2.F2_CLIENTE  = SE1.E1_CLIENTE
								AND F2.F2_LOJA     = SE1.E1_LOJA
								WHERE
									SE1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_  = ' '
								AND SE1.E1_FATPREF = E1.E1_PREFIXO
								AND SE1.E1_FATURA  = E1.E1_NUM
								AND SE1.E1_FILIAL  = E1.E1_FILIAL
								AND F2.F2_FILIAL   = E1.E1_FILIAL
								AND SE1.E1_FATURA <> ' '
								%exp:_cFilVeCoo% )
		%exp:_cFiltEmis%
		AND E3.E3_COMIS  > 0
		AND E1.E1_ORIGEM = 'FINA280'
		%exp:_cFiltro%
				
	    UNION ALL
	    
		SELECT
			E3.E3_FILIAL FILIAL,
			E1.E1_EMISSAO DTEMISSAO,
			E3.E3_EMISSAO DTBAIXA,
			E3.E3_TIPO TIPO,
			E3.E3_NUM NUMERO,
			E3.E3_SERIE		AS SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	AS PARCELA,
			E3.E3_CODCLI CODCLI,
			E3.E3_LOJA LOJA,
			E1.E1_NOMCLI NOMCLI,
			E1.E1_VALOR VLRTITULO,
			E3.E3_BASE BASECOMIS,
			E3.E3_COMIS COMISSAO,
			E3.E3_VEND CODVEND,
			A3.A3_NOME NOMEVEND,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE 
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX     = 'CMP'
				AND E5.E5_RECPAG    = 'R' ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
												FROM %Table:SE5% E5
												WHERE
													E1.E1_FILIAL    = E5.E5_FILIAL   
												AND E1.E1_PREFIXO   = E5.E5_PREFIXO
												AND E1.E1_TIPO      = E5.E5_TIPO
												AND E1.E1_NUM       = E5.E5_NUMERO
												AND E1.E1_PARCELA   = E5.E5_PARCELA
												AND E1.E1_CLIENTE   = E5.E5_CLIENTE
												AND E1.E1_LOJA      = E5.E5_LOJA
												AND E5.D_E_L_E_T_   = ' '
												AND E5.E5_TIPO     IN ('NF ','ICM')   
												AND E5.E5_TIPODOC   = 'ES'   
												AND E5.E5_SITUACA  <> 'C'
												AND E5.E5_MOTBX     = 'CMP'
												AND E5.E5_RECPAG    = 'P' ) COMPENSACAO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' ' 
				AND E5.E5_SITUACA  <> 'C'
				AND ( (		E5.E5_TIPO     = 'NF '
						AND E5.E5_TIPODOC <> 'ES'
						AND E5.E5_MOTBX   IN ('DCT','VBC')
						AND E5.E5_NATUREZ IN ('231002','231017','231019','231013','231014','231015','231016','233004','111001')
						AND E5.E5_RECPAG   = 'R')
					OR(		E5_TIPODOC     = 'DC' ) ) ) DESCONTO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX    IN ('NOR','DAC','FAT','LQ ')
				AND E5.E5_RECPAG    = 'R'
				AND E5.E5_DATA      < E3.E3_EMISSAO ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
															FROM %Table:SE5% E5
															WHERE 
																E1.E1_FILIAL    = E5.E5_FILIAL
															AND E1.E1_PREFIXO   = E5.E5_PREFIXO
															AND E1.E1_TIPO      = E5.E5_TIPO
															AND E1.E1_NUM       = E5.E5_NUMERO
															AND E1.E1_PARCELA   = E5.E5_PARCELA
															AND E1.E1_CLIENTE   = E5.E5_CLIENTE
															AND E1.E1_LOJA      = E5.E5_LOJA
															AND E5.D_E_L_E_T_   = ' '
															AND E5.E5_TIPO      = 'NF '
															AND E5.E5_TIPODOC   = 'ES'
															AND E5.E5_SITUACA  <> 'C'
															AND E5.E5_MOTBX    IN ('NOR','DAC','FAT','LQ ')
															AND E5.E5_RECPAG    = 'P' ) BAIXASANT,
			'C' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI,

         NVL((SELECT SUM(SE1_2.E1_VALOR) 
               FROM %Table:SE1% SE1_2 
               WHERE SE1_2.E1_FILIAL = E1.E1_FILIAL AND SE1_2.E1_NUM = E1.E1_NUM AND SE1_2.E1_PREFIXO='DCT' AND SE1_2.E1_CLIENTE = E1.E1_CLIENTE AND SE1_2.E1_LOJA = E1.E1_LOJA AND SE1_2.E1_PARCELA = E1.E1_PARCELA AND SE1_2.D_E_L_E_T_ =' '), 0) VALDCT, /*VALOR DESCONTO */
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE SE5.E5_FILORIG = E1.E1_FILIAL AND SE5.E5_NUMERO = E1.E1_NUM AND SE5.E5_PREFIXO='DCT' AND SE5.E5_CLIFOR = E1.E1_CLIENTE AND SE5.E5_LOJA = E1.E1_LOJA AND SE5.E5_PARCELA = E1.E1_PARCELA AND SE5.D_E_L_E_T_ =' '), 0) SE5DCT, /*VALOR DESCONTO COMPENSADO*/
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE E1.E1_PREFIXO||E1.E1_NUM||E1.E1_TIPO||E1.E1_PARCELA||E1.E1_LOJA = SE5.E5_DOCUMEN AND SE5.E5_PREFIXO='VRB' AND SE5.D_E_L_E_T_ =' '), 0) SE5VRB, /*VALOR VERBA DESCONTADO */
         NVL((SELECT SUM(F2_ICMSRET) 
               FROM %Table:SF2% SF2 
               WHERE SF2.F2_FILIAL = E1.E1_FILIAL AND SF2.F2_DOC = E1.E1_NUM AND SF2.F2_SERIE = E1.E1_PREFIXO AND SF2.D_E_L_E_T_ =' '),0) VALST /*VALOR ICM ST */
         		
		FROM %Table:SE3% E3
		JOIN %Table:SE1% E1
		ON
			E1.E1_FILIAL  = E3.E3_FILIAL
		AND E1.E1_TIPO    = E3.E3_TIPO
		AND E1.E1_PREFIXO = E3.E3_PREFIXO
		AND E1.E1_NUM     = E3.E3_NUM
		AND E1.E1_SERIE   = E3.E3_SERIE
		AND E1.E1_PARCELA = E3.E3_PARCELA
		AND E1.E1_CLIENTE = E3.E3_CODCLI
		AND E1.E1_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SA3% A3 ON A3.A3_COD = E3.E3_VEND
		
		JOIN %Table:SF2% F2
		ON
			F2.F2_FILIAL  = E3.E3_FILIAL
		AND F2.F2_DOC     = E3.E3_NUM
		AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
		AND F2.F2_CLIENTE = E3.E3_CODCLI
		AND F2.F2_LOJA    = E3.E3_LOJA
		
		
		WHERE
			E3.D_E_L_E_T_ = ' '
		AND E1.D_E_L_E_T_ = ' '
		AND A3.D_E_L_E_T_ = ' '
		AND E1.E1_NUMLIQ IN (	SELECT SE5.E5_DOCUMEN
								FROM %Table:SE5% SE5
								JOIN %Table:SF2% F2
								ON
									F2.F2_FILIAL  = SE5.E5_FILIAL
								AND F2.F2_DOC     = SE5.E5_NUMERO
								AND (F2.F2_SERIE   = SE5.E5_PREFIXO OR SE5.E5_PREFIXO = 'R')
								AND F2.F2_CLIENTE = SE5.E5_CLIFOR
								AND F2.F2_LOJA    = SE5.E5_LOJA
								WHERE
									SE5.D_E_L_E_T_  = ' '
								AND F2.D_E_L_E_T_   = ' '
								AND SE5.E5_DOCUMEN  = E1.E1_NUMLIQ
								AND SE5.E5_FILIAL   = E1.E1_FILIAL
								AND F2.F2_FILIAL    = E1.E1_FILIAL
								AND SE5.E5_DOCUMEN <> ' '
								%exp:_cFilVeCoo% )
		AND E3.E3_COMIS > 0
		%exp:_cFiltEmis%
		AND E1.E1_ORIGEM = 'FINA460'
		%exp:_cFiltro%
				
		UNION ALL
		
		SELECT
			E3.E3_FILIAL FILIAL,
			E3.E3_EMISSAO DTEMISSAO,
			E3.E3_EMISSAO DTBAIXA,
			E3.E3_TIPO TIPO,
			(	SELECT F2.F2_DOC FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
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
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) NUMERO,
				(	SELECT F2.F2_SERIE FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
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
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA PARCELA,
			E3.E3_CODCLI CODCLI,
			E3.E3_LOJA LOJA,
			A1.A1_NREDUZ NOMCLI,
			TO_NUMBER(NULL) VLRTITULO,
			E3.E3_BASE BASECOMIS,
			E3.E3_COMIS COMISSAO,
			E3.E3_VEND CODVEND,
			A3.A3_NOME NOMEVEND,
			TO_NUMBER(NULL) COMPENSACAO,
			TO_NUMBER(NULL) DESCONTO,
			TO_NUMBER(NULL) BAIXASANT,
			'D' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI,

         NVL((SELECT SUM(SE1_2.E1_VALOR) 
               FROM %Table:SE1% SE1_2 
               WHERE SE1_2.E1_FILIAL = E3.E3_FILIAL AND SE1_2.E1_NUM = E3.E3_NUM AND SE1_2.E1_PREFIXO='DCT' AND SE1_2.E1_CLIENTE = E3.E3_CODCLI AND SE1_2.E1_LOJA = E3.E3_LOJA AND SE1_2.E1_PARCELA = E3.E3_PARCELA AND SE1_2.D_E_L_E_T_ =' '), 0) VALDCT, /*VALOR DESCONTO */
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE SE5.E5_FILORIG = E3.E3_FILIAL AND SE5.E5_NUMERO = E3.E3_NUM AND SE5.E5_PREFIXO='DCT' AND SE5.E5_CLIFOR = E3.E3_CODCLI AND SE5.E5_LOJA = E3.E3_LOJA AND SE5.E5_PARCELA = E3.E3_PARCELA AND SE5.D_E_L_E_T_ =' '), 0) SE5DCT, /*VALOR DESCONTO COMPENSADO*/
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE E3.E3_PREFIXO||E3.E3_NUM||E3.E3_TIPO||E3.E3_PARCELA||E3.E3_LOJA = SE5.E5_DOCUMEN AND SE5.E5_PREFIXO='VRB' AND SE5.D_E_L_E_T_ =' '), 0) SE5VRB, /*VALOR VERBA DESCONTADO */
         NVL((SELECT SUM(F2_ICMSRET) 
               FROM %Table:SF2% SF2 
               WHERE SF2.F2_FILIAL = E3.E3_FILIAL AND SF2.F2_DOC = E3.E3_NUM AND SF2.F2_SERIE = E3.E3_PREFIXO AND SF2.D_E_L_E_T_ =' '),0) VALST /*VALOR ICM ST */
         		
		FROM %Table:SE3% E3
		JOIN %Table:SA3% A3 ON E3.E3_VEND = A3.A3_COD
		JOIN %Table:SA1% A1 ON A1.A1_COD = E3.E3_CODCLI AND A1.A1_LOJA = E3.E3_LOJA
		WHERE
			E3.D_E_L_E_T_ = ' '
		AND A3.D_E_L_E_T_ = ' ' 
		%exp:_cFiltronc%  
		AND A1.D_E_L_E_T_ = ' '
		AND E3.E3_TIPO    = 'NCC'
		%exp:_cFiltEmis%
		
		AND E3.E3_NUM    IN (	SELECT D1.D1_DOC FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
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
								%exp:_cFilVeCoo% )
		
		UNION ALL
		
		SELECT
			E3.E3_FILIAL	FILIAL,
			E3.E3_EMISSAO	DTEMISSAO,
			E3.E3_EMISSAO	DTBAIXA,
			E3.E3_TIPO		TIPO,
				(	SELECT F2.F2_DOC FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
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
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) NUMERO,
				(	SELECT F2.F2_SERIE FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
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
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	PARCELA,
			E3.E3_CODCLI	CODCLI,
			E3.E3_LOJA		LOJA,
			A1.A1_NREDUZ	NOMCLI,
			TO_NUMBER(NULL)	VLRTITULO,
			E3.E3_BASE		BASECOMIS,
			E3.E3_COMIS		COMISSAO,
			E3.E3_VEND		CODVEND,
			A3.A3_NOME		NOMEVEND,
			TO_NUMBER(NULL) COMPENSACAO,
			TO_NUMBER(NULL) DESCONTO,
			TO_NUMBER(NULL) BAIXASANT,
			'D'				ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI,

         NVL((SELECT SUM(SE1_2.E1_VALOR) 
               FROM %Table:SE1% SE1_2 
               WHERE SE1_2.E1_FILIAL = E3.E3_FILIAL AND SE1_2.E1_NUM = E3.E3_NUM AND SE1_2.E1_PREFIXO='DCT' AND SE1_2.E1_CLIENTE = E3.E3_CODCLI AND SE1_2.E1_LOJA = E3.E3_LOJA AND SE1_2.E1_PARCELA = E3.E3_PARCELA AND SE1_2.D_E_L_E_T_ =' '), 0) VALDCT, /*VALOR DESCONTO */
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE SE5.E5_FILORIG = E3.E3_FILIAL AND SE5.E5_NUMERO = E3.E3_NUM AND SE5.E5_PREFIXO='DCT' AND SE5.E5_CLIFOR = E3.E3_CODCLI AND SE5.E5_LOJA = E3.E3_LOJA AND SE5.E5_PARCELA = E3.E3_PARCELA AND SE5.D_E_L_E_T_ =' '), 0) SE5DCT, /*VALOR DESCONTO COMPENSADO*/
         NVL((SELECT SUM(SE5.E5_VALOR) 
               FROM %Table:SE5% SE5 
               WHERE E3.E3_PREFIXO||E3.E3_NUM||E3.E3_TIPO||E3.E3_PARCELA||E3.E3_LOJA = SE5.E5_DOCUMEN AND SE5.E5_PREFIXO='VRB' AND SE5.D_E_L_E_T_ =' '), 0) SE5VRB, /*VALOR VERBA DESCONTADO */
         NVL((SELECT SUM(F2_ICMSRET) 
               FROM %Table:SF2% SF2 
               WHERE SF2.F2_FILIAL = E3.E3_FILIAL AND SF2.F2_DOC = E3.E3_NUM AND SF2.F2_SERIE = E3.E3_PREFIXO AND SF2.D_E_L_E_T_ =' '),0) VALST /*VALOR ICM ST */
         		
		FROM %Table:SE3% E3
		JOIN %Table:SA3% A3 ON E3.E3_VEND = A3.A3_COD
		JOIN %Table:SA1% A1 ON A1.A1_COD = E3.E3_CODCLI AND A1.A1_LOJA = E3.E3_LOJA
		WHERE
			E3.D_E_L_E_T_  = ' '
		AND A3.D_E_L_E_T_  = ' '
		AND A1.D_E_L_E_T_  = ' '
		AND E3.E3_TIPO     = 'NCC' 
		%exp:_cFiltronc%  
		AND A3.A3_SUPER   <> ' '
		%exp:_cFilCooVe%
		AND E3.E3_NUM NOT IN (	SELECT D1.D1_DOC
								FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
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
								%exp:_cFilVeCoo% )
		ORDER BY CODVEND, ORDENADACAO, FILIAL, DTBAIXA, NUMERO, PARCELA
		
		EndSql
		
		/*
		//==============================================================================================
		//Seleciona os creditos e debitos de comissao gerados grupando por Filial, relatorio sintetico
		//==============================================================================================
		*/
   Case _nOpcao == 2 
	    	
	    	BeginSql alias _cAlias
	    	 	    	
				SELECT
				      E3.E3_FILIAL		AS FILIAL,
		              E3.E3_VEND		AS CODVEND,
		              A3.A3_NOME		AS NOMEVEND,
		              A3.A3_SUPER		AS CODSUPERV,
		              DESCSUPER.A3_NOME	AS NOMESUP,
		              E3.E3_TIPO		AS TIPO,
		              A3.A3_I_DEDUC		AS DEDUCAO,
		              E3.E3_I_ORIGE		AS ORIGEM,
		              SUM(E3.E3_COMIS)	AS COMISSAO,
		              SUM(E3.E3_BASE)	AS VLRRECEB,
		              SUM(E1.E1_VALOR)	AS VLRFATU,
		              'C'				AS ORDENADACAO
			 	FROM %Table:SE3% E3
      		    JOIN %Table:SE1% E1
      		          ON E1.E1_FILIAL   = E3.E3_FILIAL 
                      AND E1.E1_TIPO    = E3.E3_TIPO
                      AND E1.E1_PREFIXO = E3.E3_PREFIXO
                      AND E1.E1_NUM     = E3.E3_NUM  
                      AND E1.E1_SERIE   = E3.E3_SERIE
                      AND E1.E1_PARCELA = E3.E3_PARCELA
                      AND E1.E1_CLIENTE = E3.E3_CODCLI
                      AND E1.E1_LOJA    = E3.E3_LOJA
                    
			   JOIN %Table:SF2% F2 
			   		  ON F2.F2_FILIAL   = E3.E3_FILIAL
			          AND F2.F2_DOC     = E3.E3_NUM
			          AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
			          AND F2.F2_CLIENTE = E3.E3_CODCLI
			          AND F2.F2_LOJA    = E3.E3_LOJA
			   JOIN %Table:SA3% A3 
			          ON A3.A3_COD = E3.E3_VEND      
                ,
                (
                  SELECT
                        SA3.A3_NOME,SA3.A3_COD
                  FROM 
                        %Table:SA3% SA3
                  WHERE    
                        SA3.D_E_L_E_T_ = ' '                                                        
                ) DESCSUPER
				WHERE
				      E3.D_E_L_E_T_     = ' '
				      AND E1.D_E_L_E_T_ = ' '    
				      AND F2.D_E_L_E_T_ = ' '   
				      AND A3.D_E_L_E_T_ = ' '
              		  AND DESCSUPER.A3_COD = A3.A3_SUPER    
              		  AND E3.E3_COMIS > 0               		  
              		  AND E1.E1_ORIGEM NOT IN ('FINA460','FINA280')	
              		  %exp:_cFiltro%
               GROUP BY 
		             E3.E3_FILIAL, 
		             E3.E3_VEND,
		             A3.A3_NOME,
		             A3.A3_SUPER,
		             DESCSUPER.A3_NOME,
		             E3.E3_TIPO,
		             A3.A3_I_DEDUC,
		             E3.E3_I_ORIGE
              UNION ALL
				SELECT
				      E3.E3_FILIAL      AS FILIAL,              
		              E3.E3_VEND        AS CODVEND,
		              A3.A3_NOME        AS NOMEVEND,		
		              A3.A3_SUPER       AS CODSUPERV,
		              DESCSUPER.A3_NOME AS NOMESUP,
		              E3.E3_TIPO        AS TIPO,             
		              A3.A3_I_DEDUC     AS DEDUCAO,
		              E3.E3_I_ORIGE     AS ORIGEM,
		              SUM(E3.E3_COMIS)  AS COMISSAO,
		              SUM(E3.E3_BASE)   AS VLRRECEB,
		              SUM(E1.E1_VALOR)  AS VLRFATU,
                      'C' ORDENADACAO
			 	FROM
                     %Table:SE3% E3
      		    JOIN %Table:SE1% E1 
      		          ON E1.E1_FILIAL   = E3.E3_FILIAL 
                      AND E1.E1_TIPO    = E3.E3_TIPO
                      AND E1.E1_PREFIXO = E3.E3_PREFIXO
                      AND E1.E1_NUM     = E3.E3_NUM  
                      AND E1.E1_SERIE   = E3.E3_SERIE
                      AND E1.E1_PARCELA = E3.E3_PARCELA
                      AND E1.E1_CLIENTE = E3.E3_CODCLI
                      AND E1.E1_LOJA    = E3.E3_LOJA                    
			   JOIN %Table:SA3% A3 
			          ON A3.A3_COD = E3.E3_VEND      
                ,
                (
                  SELECT
                        SA3.A3_NOME,SA3.A3_COD
                  FROM 
                        %Table:SA3% SA3
                  WHERE    
                        SA3.D_E_L_E_T_ = ' '                                                        
                ) DESCSUPER
				WHERE
				      E3.D_E_L_E_T_     = ' '
				      AND E1.D_E_L_E_T_ = ' '      
				      AND A3.D_E_L_E_T_ = ' '
              		  AND DESCSUPER.A3_COD = A3.A3_SUPER   
              		  AND E3.E3_COMIS > 0                     
                      AND E1.E1_NUM IN (
					                          SELECT
					                                 SE1.E1_FATURA
					                          FROM 
					                                 %Table:SE1% SE1
					                                 JOIN %Table:SF2% F2
					                                 ON  F2.F2_FILIAL  = SE1.E1_FILIAL
					                                 AND F2.F2_DOC     = SE1.E1_NUM
					                                 AND (F2.F2_SERIE   = SE1.E1_SERIE OR SE1.E1_SERIE = 'R')
					                                 AND F2.F2_CLIENTE = SE1.E1_CLIENTE
					                                 AND F2.F2_LOJA    = SE1.E1_LOJA
					                         WHERE       
					                                 SE1.D_E_L_E_T_ = ' '
					                                 AND F2.D_E_L_E_T_ = ' '
					                                 AND SE1.E1_FATPREF = E1.E1_PREFIXO
					                                 AND SE1.E1_FATURA  = E1.E1_NUM
					                                 AND SE1.E1_FILIAL  = E1.E1_FILIAL
					                                 AND F2.F2_FILIAL   = E1.E1_FILIAL   
					                                 AND SE1.E1_FATURA <> ' '
					                                 %exp:_cFilVeCoo%					                                 					                                 
					                          ) 	
					  %exp:_cFiltEmis%					                          		                          
					  AND E1.E1_ORIGEM = 'FINA280'	
                GROUP BY E3.E3_FILIAL, E3.E3_VEND, A3.A3_NOME, A3.A3_SUPER, DESCSUPER.A3_NOME, E3.E3_TIPO, A3.A3_I_DEDUC, E3.E3_I_ORIGE

				UNION ALL  

				SELECT
				      E3.E3_FILIAL      AS FILIAL,              
		              E3.E3_VEND        AS CODVEND,
		              A3.A3_NOME        AS NOMEVEND,		
		              A3.A3_SUPER       AS CODSUPERV,
		              DESCSUPER.A3_NOME AS NOMESUP,
		              E3.E3_TIPO        AS TIPO,             
		              A3.A3_I_DEDUC     AS DEDUCAO,
		              E3.E3_I_ORIGE     AS ORIGEM,
		              SUM(E3.E3_COMIS)  AS COMISSAO,
		              SUM(E3.E3_BASE)   AS VLRRECEB,
		              SUM(E1.E1_VALOR)  AS VLRFATU,
                      'C' ORDENADACAO
			 	FROM
                     %Table:SE3% E3
      		    JOIN %Table:SE1% E1 
      		          ON E1.E1_FILIAL   = E3.E3_FILIAL 
                      AND E1.E1_TIPO    = E3.E3_TIPO
                      AND E1.E1_PREFIXO = E3.E3_PREFIXO
                      AND E1.E1_NUM     = E3.E3_NUM  
                      AND E1.E1_SERIE   = E3.E3_SERIE
                      AND E1.E1_PARCELA = E3.E3_PARCELA
                      AND E1.E1_CLIENTE = E3.E3_CODCLI
                      AND E1.E1_LOJA    = E3.E3_LOJA
                      
			   JOIN %Table:SA3% A3 
			          ON A3.A3_COD = E3.E3_VEND      
                ,
                (
                  SELECT
                        SA3.A3_NOME,SA3.A3_COD
                  FROM 
                        %Table:SA3% SA3
                  WHERE    
                        SA3.D_E_L_E_T_ = ' '                                                        
                ) DESCSUPER
				WHERE
				      E3.D_E_L_E_T_     = ' '
				      AND E1.D_E_L_E_T_ = ' '    
				      AND A3.D_E_L_E_T_ = ' '
              		  AND DESCSUPER.A3_COD = A3.A3_SUPER   
              		  AND E3.E3_COMIS > 0   
                    	        AND E1.E1_NUMLIQ IN (
                          SELECT
                                 SE5.E5_DOCUMEN 
                          FROM 
                                 %Table:SE5% SE5
                                 JOIN %Table:SF2% F2
                                 ON  F2.F2_FILIAL  = SE5.E5_FILIAL
                                 AND F2.F2_DOC     = SE5.E5_NUMERO
                                 AND (F2.F2_SERIE   = SE5.E5_PREFIXO OR SE5.E5_PREFIXO = 'R')
                                 AND F2.F2_CLIENTE = SE5.E5_CLIFOR
                                 AND F2.F2_LOJA    = SE5.E5_LOJA
                         WHERE       
                                 SE5.D_E_L_E_T_ = ' '
                                 AND F2.D_E_L_E_T_  = ' '
                                 AND SE5.E5_DOCUMEN = E1.E1_NUMLIQ
                                 AND SE5.E5_FILIAL  = E1.E1_FILIAL
                                 AND F2.F2_FILIAL   = E1.E1_FILIAL  
                                 AND SE5.E5_DOCUMEN  <> ' '
                                 %exp:_cFilVeCoo%
                          )     
                           %exp:_cFiltEmis%	
       	 			       AND E1.E1_ORIGEM = 'FINA460'	
                GROUP BY E3.E3_FILIAL, E3.E3_VEND, A3.A3_NOME, A3.A3_SUPER, DESCSUPER.A3_NOME, E3.E3_TIPO, A3.A3_I_DEDUC,E3.E3_I_ORIGE   

				UNION ALL              

				SELECT
				      E3.E3_FILIAL      AS FILIAL,
				      E3.E3_VEND        AS CODVEND,
				      A3.A3_NOME        AS NOMEVEND,
				      A3.A3_SUPER       AS CODSUPERV,
				      DESCSUPER.A3_NOME AS NOMESUP,
				      E3.E3_TIPO        AS TIPO, 
				      A3.A3_I_DEDUC     AS DEDUCAO,
				      E3.E3_I_ORIGE     AS ORIGEM,
				      SUM(E3.E3_COMIS)  AS COMISSAO,
				      TO_NUMBER(NULL)   AS VLRRECEB,
		              TO_NUMBER(NULL)   AS VLRFATU,
		              'D' ORDENADACAO    
				FROM
    				  %Table:SE3% E3,%table:SA3% A3,
      				(
                           SELECT 
                                 DISTINCT F2.F2_VEND1,D1.D1_FILIAL,D1.D1_DOC,D1.D1_SERIE,D1.D1_FORNECE,D1.D1_LOJA  FROM %Table:SD1% D1,%table:SF2% F2
                           WHERE 
                                D1.D_E_L_E_T_ = ' '
                                AND F2.D_E_L_E_T_ = ' '                  
                                AND F2.F2_FILIAL  = D1.D1_FILIAL
                                AND F2.F2_DOC     = D1.D1_NFORI
                                AND F2.F2_SERIE   = D1.D1_SERIORI
                                AND F2.F2_CLIENTE = D1.D1_FORNECE 
                                AND F2.F2_LOJA    = D1.D1_LOJA
                                 %exp:_cFilVeCoo%                                                                                    
      			    ) COORDENAD,
			       (
			        	   SELECT
			            		SA3.A3_NOME,SA3.A3_COD
			               FROM 
			                    %Table:SA3% SA3
			               WHERE    
			                    SA3.D_E_L_E_T_ = ' '                                                        
			       ) DESCSUPER
			WHERE
			      E3.D_E_L_E_T_        = ' '  
			      AND A3.D_E_L_E_T_    = ' '
			      AND E3.E3_FILIAL     = COORDENAD.D1_FILIAL
			      AND E3.E3_NUM        = COORDENAD.D1_DOC
			      AND E3.E3_SERIE      = COORDENAD.D1_SERIE
			      AND E3.E3_CODCLI     = COORDENAD.D1_FORNECE 
			      AND E3.E3_LOJA       = COORDENAD.D1_LOJA
			      AND A3.A3_COD        = E3.E3_VEND 
			      %exp:_cFiltEmis%
			      AND E3.E3_TIPO       = 'NCC'                                                                                     
		   GROUP BY E3.E3_FILIAL,
                 E3.E3_VEND,
                 A3.A3_NOME,
                 A3.A3_SUPER,
                 DESCSUPER.A3_NOME,
                 E3.E3_TIPO,
                 A3.A3_I_DEDUC,
                 E3.E3_I_ORIGE
	      UNION ALL
		  SELECT
		         E3.E3_FILIAL      AS FILIAL,
		         E3.E3_VEND        AS CODVEND,
		         A3.A3_NOME        AS NOMEVEND,
		         A3.A3_SUPER       AS CODSUPERV,
		         DESCSUPER.A3_NOME AS NOMESUP,
		         E3.E3_TIPO        AS TIPO,
		         A3.A3_I_DEDUC     AS DEDUCAO,
		         E3.E3_I_ORIGE     AS ORIGEM,
		         SUM(E3.E3_COMIS)  AS COMISSAO,
		         TO_NUMBER(NULL)   AS VLRRECEB,
		         TO_NUMBER(NULL)   AS VLRFATU,
		         'D' ORDENADACAO  
		 FROM
		        %Table:SE3% E3    
		        JOIN %Table:SA3% A3
		        ON E3.E3_VEND = A3.A3_COD
          ,
         (
                  SELECT
                        SA3.A3_NOME,SA3.A3_COD
                  FROM 
                        %Table:SA3% SA3
                  WHERE    
                        SA3.D_E_L_E_T_ = ' '                                                        
         ) DESCSUPER
	     WHERE
      			E3.D_E_L_E_T_ = ' '    
		        AND A3.D_E_L_E_T_ = ' '  
		        AND DESCSUPER.A3_COD = A3.A3_SUPER
		        AND E3.E3_TIPO = 'NCC' 
		        AND A3.A3_COD <> A3.A3_SUPER   
		        AND A3.A3_SUPER <> ' '  
		        %exp:_cFilCooVe%
		        AND E3.E3_NUM NOT IN (
                           SELECT D1.D1_DOC FROM %Table:SD1% D1,%table:SF2% F2
                           WHERE 
                                D1.D_E_L_E_T_ = ' '
                                AND F2.D_E_L_E_T_ = ' '
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
                                %exp:_cFilVeCoo% 
                                                                                                                
			      )   
		GROUP BY E3.E3_FILIAL, E3.E3_VEND, A3.A3_NOME, A3.A3_SUPER, DESCSUPER.A3_NOME, E3.E3_TIPO, A3.A3_I_DEDUC, E3.E3_I_ORIGE
		
		ORDER BY CODSUPERV, CODVEND, FILIAL
		
    	EndSql
            	
	Case _nOpcao == 3
	
		_cQuery := " SELECT "
		_cQuery += "    SF2.F2_FILIAL       AS F2_FILIAL   		, "
		_cQuery += "    SF2.F2_DOC          AS F2_DOC 		  	, "
		_cQuery += "    SF2.F2_SERIE        AS F2_SERIE   		, "
		_cQuery += "    SF2.F2_EMISSAO      AS F2_EMISSAO  		, "
		_cQuery += "    SF2.F2_CLIENTE      AS F2_CLIENTE   	, "
		_cQuery += "    SF2.F2_LOJA         AS F2_LOJA   		, "
		_cQuery += "    SF2.F2_VEND1        AS F2_VEND1   		, "
		_cQuery += "    SF2.F2_VEND2        AS F2_VEND2   		, "
		_cQuery += "    SF2.F2_VEND3        AS F2_VEND3   		, "
		_cQuery += "    SF2.F2_VEND4        AS F2_VEND4   		, "
		_cQuery += "    SF2.F2_VEND5        AS F2_VEND5   		, " 
		_cQuery += "    SUM((SD2.D2_VALBRUT-SD2.D2_VALDEV)) AS VALTOT           , "
		_cQuery += "    SUM(SD2.D2_COMIS1*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS1           , "
		_cQuery += "    SUM(SD2.D2_COMIS2*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS2           , "
		_cQuery += "    SUM(SD2.D2_COMIS3*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS3           , "
		_cQuery += "    SUM(SD2.D2_COMIS4*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS4           , "
		_cQuery += "    SUM(SD2.D2_COMIS5*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS5           , "  
      _cQuery += "    0  AS VALDCT,            "  
      _cQuery += "    0  AS SE5DCT,            "  
      _cQuery += "    0  AS SE5VRB,            "  
      _cQuery += "    0  AS VALST,            "  
      _cQuery += "    0  AS COMPENSACAO,       "                    
      _cQuery += "    0  AS VLRTITULO            "                    
		_cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
		_cQuery += " JOIN "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
		_cQuery += " JOIN "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD AND SB1.B1_FILIAL = '  '"
		_cQuery += " JOIN "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO "
		_cQuery += " JOIN "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF "
		_cQuery += " WHERE "
		_cQuery += "     SF2.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SF4.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAY.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SB1.B1_TIPO    = 'PA' "
		_cQuery += " AND ZAY.ZAY_TPOPER	= 'B' "
		//_cQuery += " AND (SD2.D2_VALBRUT-SD2.D2_VALDEV) > 0"  
		_cQuery +=   _cfiltrobon
		_cQuery += " GROUP BY SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE,SF2.F2_EMISSAO, SF2.F2_CLIENTE,SF2.F2_LOJA,SF2.F2_VEND1, SF2.F2_VEND2, SF2.F2_VEND3, SF2.F2_VEND4, SF2.F2_VEND5 " 
		_cQuery += " ORDER BY SF2.F2_FILIAL,SF2.F2_DOC,SF2.F2_SERIE "
   
      If Select(_cAlias) > 0
         (_cAlias)->( DBCloseArea() )
      EndIf
      
      _cQuery := ChangeQuery(_cQuery)
		
		MPSysOpenQuery( _cQuery , _cAlias ) 
   Case _nOpcao == 4
        //========= Query Duplicatas Vencidas        
        _cQuery := " SELECT "
		_cQuery += "    F2.F2_FILIAL       AS F2_FILIAL   		, "
		_cQuery += "    F2.F2_DOC          AS F2_DOC 		  	, "
		_cQuery += "    F2.F2_SERIE        AS F2_SERIE   		, "
		_cQuery += "    F2.F2_EMISSAO      AS F2_EMISSAO  		, "
		_cQuery += "    F2.F2_CLIENTE      AS F2_CLIENTE   	    , "
		_cQuery += "    F2.F2_LOJA         AS F2_LOJA   		, "
		_cQuery += "    F2.F2_VEND1        AS F2_VEND1   		, "
		_cQuery += "    F2.F2_VEND2        AS F2_VEND2   		, "
		_cQuery += "    F2.F2_VEND3        AS F2_VEND3   		, "
		_cQuery += "    F2.F2_VEND4        AS F2_VEND4   		, " 
		_cQuery += "    F2.F2_VEND5        AS F2_VEND5   		, " 
		_cQuery += "    SUM(D2.D2_ICMSRET) AS ICMSRET          , " 			
        _cQuery += "    SUM(E1.E1_SALDO * (D2.D2_TOTAL / F2.F2_VALMERC))   AS VALTOT           , "
		_cQuery += "    SUM(D2.D2_COMIS1 * (E1.E1_SALDO - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS1 , "
		_cQuery += "    SUM(D2.D2_COMIS2 * (E1.E1_SALDO - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS2 , "
		_cQuery += "    SUM(D2.D2_COMIS3 * (E1.E1_SALDO - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS3 , "
		_cQuery += "    SUM(D2.D2_COMIS4 * (E1.E1_SALDO - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS4, "
        _cQuery += "    SUM(D2.D2_COMIS5 * (E1.E1_SALDO - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS5, "
        _cQuery += "    SUM((E1.E1_SALDO - "
		_cQuery += "  (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' ) "		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC))   AS BASECOMIS  "
		_cQuery += "    FROM " + RetSqlName("SE1") + " E1 "
	    _cQuery += "    INNER JOIN " + RetSqlName("SF2") + " F2 "
	    _cQuery += "    ON "
	    _cQuery += "    F2.F2_FILIAL  = E1.E1_FILIAL "
        _cQuery += "    AND F2.F2_DOC     = E1.E1_NUM "
        _cQuery += "    AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R') "
        _cQuery += "    AND F2.F2_CLIENTE = E1.E1_CLIENTE "
        _cQuery += "    AND F2.F2_LOJA    = E1.E1_LOJA "
        _cQuery += "    INNER JOIN " + RetSqlName("SD2") + " D2 "
        _cQuery += "    ON "
	    _cQuery += "    F2.F2_FILIAL      = D2.D2_FILIAL "
        _cQuery += "    AND F2.F2_DOC     = D2.D2_DOC "
        _cQuery += "    AND F2.F2_SERIE   = D2.D2_SERIE "
        _cQuery += "    AND F2.F2_CLIENTE = D2.D2_CLIENTE "
        _cQuery += "    AND F2.F2_LOJA    = D2.D2_LOJA "
		_cQuery += "    WHERE "
		_cQuery += "    E1.D_E_L_E_T_ = ' ' " 
		_cQuery += "    AND F2.D_E_L_E_T_ = ' ' " 
		_cQuery += "    AND E1.E1_SALDO   > 0
		_cQuery += "    AND E1.E1_VENCREA < '" + DToS( Date() ) + "' "
		_cQuery += "    AND E1.E1_ORIGEM  NOT IN ( 'FINA460' , 'FINA280' )
       	_cQuery += "    AND F2.F2_VEND1 = E1.E1_VEND1  "
		_cQuery += "    AND F2.F2_VEND2 = E1.E1_VEND2  "
		_cQuery += "    AND F2.F2_VEND3 = E1.E1_VEND3  "
		_cQuery += "    AND F2.F2_VEND4 = E1.E1_VEND4  " 
        _cQuery +=      _cFilSemBaixa
        _cQuery += "    GROUP BY F2.F2_FILIAL,F2.F2_DOC, F2.F2_SERIE, F2.F2_EMISSAO, F2.F2_CLIENTE, F2.F2_LOJA, F2.F2_VEND1, F2.F2_VEND2, F2.F2_VEND3, F2.F2_VEND4, F2.F2_VEND5 "
		_cQuery += "    UNION ALL "
		//==================== Query Duplicatas a Vencer
		_cQuery += " SELECT "
		_cQuery += "    F2.F2_FILIAL       AS F2_FILIAL   		, "
		_cQuery += "    F2.F2_DOC          AS F2_DOC 		  	, "
		_cQuery += "    F2.F2_SERIE        AS F2_SERIE   		, "
		_cQuery += "    F2.F2_EMISSAO      AS F2_EMISSAO  		, "
		_cQuery += "    F2.F2_CLIENTE      AS F2_CLIENTE   	, "
		_cQuery += "    F2.F2_LOJA         AS F2_LOJA   		, "
		_cQuery += "    F2.F2_VEND1        AS F2_VEND1   		, "
		_cQuery += "    F2.F2_VEND2        AS F2_VEND2   		, "
		_cQuery += "    F2.F2_VEND3        AS F2_VEND3   		, "
		_cQuery += "    F2.F2_VEND4        AS F2_VEND4   		, " 
		_cQuery += "    F2.F2_VEND5        AS F2_VEND5   		, " 
		_cQuery += "    SUM(D2.D2_ICMSRET) AS ICMSRET          , " 			
        _cQuery += "    SUM((E1.E1_SALDO + E1.E1_SDACRES - E1_SDDECRE) * (D2.D2_TOTAL / F2.F2_VALMERC)) AS VALTOT           , "
		_cQuery += "    SUM(D2.D2_COMIS1 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS1 , "
		_cQuery += "    SUM(D2.D2_COMIS2 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS2 , "
		_cQuery += "    SUM(D2.D2_COMIS3 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS3 , "
		_cQuery += "    SUM(D2.D2_COMIS4 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS4, "
        _cQuery += "    SUM(D2.D2_COMIS5 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS5, "
        _cQuery += "    SUM((E1.E1_SALDO + E1.E1_SDACRES - E1_SDDECRE - "
		_cQuery += "  (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' ) "		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC)) AS BASECOMIS "
		_cQuery += "    FROM " + RetSqlName("SE1") + " E1 "
	   _cQuery += "    INNER JOIN " + RetSqlName("SF2") + " F2 "
	   _cQuery += "    ON "
	   _cQuery += "    F2.F2_FILIAL  = E1.E1_FILIAL "
      _cQuery += "    AND F2.F2_DOC     = E1.E1_NUM "
      _cQuery += "    AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R') "
      _cQuery += "    AND F2.F2_CLIENTE = E1.E1_CLIENTE "
      _cQuery += "    AND F2.F2_LOJA    = E1.E1_LOJA "
      _cQuery += "    INNER JOIN " + RetSqlName("SD2") + " D2 "
      _cQuery += "    ON "
	   _cQuery += "    F2.F2_FILIAL      = D2.D2_FILIAL "
      _cQuery += "    AND F2.F2_DOC     = D2.D2_DOC "
      _cQuery += "    AND F2.F2_SERIE  = D2.D2_SERIE "
      _cQuery += "    AND F2.F2_CLIENTE = D2.D2_CLIENTE "
      _cQuery += "    AND F2.F2_LOJA    = D2.D2_LOJA "
		_cQuery += "    WHERE "
	   _cQuery += "    E1.D_E_L_E_T_ = ' ' " 
		_cQuery += "    AND F2.D_E_L_E_T_ = ' ' " 
		_cQuery += "    AND F2.F2_VEND3   <> ' '
		_cQuery += "    AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0
		_cQuery += "    AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE('" + DToS( Date() ) + "' , 'YYYY/MM/DD' ) >= 0
		_cQuery += "    AND E1.E1_ORIGEM NOT IN ( 'FINA460' , 'FINA280' )
		_cQuery +=      _cFilSemBaixa   
      _cQuery += "    GROUP BY F2.F2_FILIAL,F2.F2_DOC, F2.F2_SERIE, F2.F2_EMISSAO, F2.F2_CLIENTE, F2.F2_LOJA, F2.F2_VEND1, F2.F2_VEND2, F2.F2_VEND3, F2.F2_VEND4 , F2.F2_VEND5"
		_cQuery += "    UNION ALL "
		_cQuery += " SELECT "
		_cQuery += "    F2.F2_FILIAL       AS F2_FILIAL   		, "
		_cQuery += "    F2.F2_DOC          AS F2_DOC 		  	, "
		_cQuery += "    F2.F2_SERIE        AS F2_SERIE   		, "
		_cQuery += "    F2.F2_EMISSAO      AS F2_EMISSAO  		, "
		_cQuery += "    F2.F2_CLIENTE      AS F2_CLIENTE   	    , "
		_cQuery += "    F2.F2_LOJA         AS F2_LOJA   		, "
		_cQuery += "    F2.F2_VEND1        AS F2_VEND1   		, "
		_cQuery += "    F2.F2_VEND2        AS F2_VEND2   		, "
		_cQuery += "    F2.F2_VEND3        AS F2_VEND3   		, "
		_cQuery += "    F2.F2_VEND4        AS F2_VEND4   		, " 
		_cQuery += "    F2.F2_VEND5        AS F2_VEND5   		, " 
		_cQuery += "    SUM(D2.D2_ICMSRET) AS ICMSRET           , " 				
      _cQuery += "    SUM((E1.E1_SALDO + E1.E1_SDACRES - E1_SDDECRE) * (D2.D2_TOTAL / F2.F2_VALMERC))   AS VALTOT           , "
		_cQuery += "    SUM(D2.D2_COMIS1 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 )  AS COMIS1 , "
		_cQuery += "    SUM(D2.D2_COMIS2 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 )  AS COMIS2 , "
		_cQuery += "    SUM(D2.D2_COMIS3 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 )  AS COMIS3 , "
		_cQuery += "    SUM(D2.D2_COMIS4 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 )  AS COMIS4, "
      _cQuery += "    SUM(D2.D2_COMIS5 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 )  AS COMIS5, "
      _cQuery += "    SUM((E1.E1_SALDO + E1.E1_SDACRES - E1_SDDECRE - "
      _cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' ) "				
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC)) AS BASECOMIS  "
		_cQuery += "    FROM " + RetSqlName("SE1") + " E1 "
	    _cQuery += "    INNER JOIN " + RetSqlName("SF2") + " F2 "
	    _cQuery += "    ON "
	    _cQuery += "    F2.F2_FILIAL  = E1.E1_FILIAL "
        _cQuery += "    AND F2.F2_DOC     = E1.E1_NUM "
        _cQuery += "    AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R') "
        _cQuery += "    AND F2.F2_CLIENTE = E1.E1_CLIENTE "
        _cQuery += "    AND F2.F2_LOJA    = E1.E1_LOJA "
        _cQuery += "    INNER JOIN " + RetSqlName("SD2") + " D2 "
        _cQuery += "    ON "
	    _cQuery += "    F2.F2_FILIAL      = D2.D2_FILIAL "
        _cQuery += "    AND F2.F2_DOC     = D2.D2_DOC "
        _cQuery += "    AND F2.F2_SERIE   = D2.D2_SERIE "
        _cQuery += "    AND F2.F2_CLIENTE = D2.D2_CLIENTE "
        _cQuery += "    AND F2.F2_LOJA    = D2.D2_LOJA "
		_cQuery += "    WHERE "
		_cQuery += "    E1.D_E_L_E_T_ = ' ' " 
		_cQuery += "    AND F2.D_E_L_E_T_ = ' ' " 
        _cQuery += "    AND E1.E1_ORIGEM  = 'FINA280' "
		_cQuery += "    AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0 "
		_cQuery += "    AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE('"+DToS(date())+"', 'YYYY/MM/DD' ) >= 0 "
		_cQuery += "    AND E1.E1_NUM    IN (	SELECT SE1.E1_FATURA "
		_cQuery += "                         	FROM " + RetSqlName("SE1") + " SE1 "
		_cQuery += "                         	JOIN " + RetSqlName("SF2") + " SF2 "
		_cQuery += "                         	ON  SF2.F2_FILIAL   = SE1.E1_FILIAL "
		_cQuery += "                         	AND SF2.F2_DOC      = SE1.E1_NUM "
		_cQuery += "                         	AND (SF2.F2_SERIE   = SE1.E1_PREFIXO OR SE1.E1_PREFIXO = 'R') "
		_cQuery += "                         	AND SF2.F2_CLIENTE  = SE1.E1_CLIENTE "
		_cQuery += "                         	AND SF2.F2_LOJA     = SE1.E1_LOJA "
		_cQuery += "                         	WHERE "
		_cQuery += "                         	SE1.D_E_L_E_T_ = ' ' "
		_cQuery += "                         	AND SF2.D_E_L_E_T_  = ' ' "
		_cQuery += "                         	AND SF2.F2_VEND3   <> ' ' "
		_cQuery += "                         	AND SE1.E1_FATPREF = E1.E1_PREFIXO "
		_cQuery += "                         	AND SE1.E1_FATURA  = E1.E1_NUM "
		_cQuery += "                         	AND SE1.E1_FILIAL  = E1.E1_FILIAL "
		_cQuery += "                         	AND SF2.F2_FILIAL  = E1.E1_FILIAL "
		_cQuery += "                         	AND SE1.E1_FATURA <> ' ' ) "
		_cQuery +=      _cFilSemBaixa 
        _cQuery += "    GROUP BY F2.F2_FILIAL,F2.F2_DOC, F2.F2_SERIE, F2.F2_EMISSAO, F2.F2_CLIENTE, F2.F2_LOJA, F2.F2_VEND1, F2.F2_VEND2, F2.F2_VEND3, F2.F2_VEND4 , F2.F2_VEND5"
		_cQuery += "    UNION ALL "
		_cQuery += " SELECT "
		_cQuery += "    F2.F2_FILIAL       AS F2_FILIAL   		, "
		_cQuery += "    F2.F2_DOC          AS F2_DOC 		  	, "
		_cQuery += "    F2.F2_SERIE        AS F2_SERIE   		, "
		_cQuery += "    F2.F2_EMISSAO      AS F2_EMISSAO  		, "
		_cQuery += "    F2.F2_CLIENTE      AS F2_CLIENTE   	, "
		_cQuery += "    F2.F2_LOJA         AS F2_LOJA   		, "
		_cQuery += "    F2.F2_VEND1        AS F2_VEND1   		, "
		_cQuery += "    F2.F2_VEND2        AS F2_VEND2   		, "
		_cQuery += "    F2.F2_VEND3        AS F2_VEND3   		, "
		_cQuery += "    F2.F2_VEND4        AS F2_VEND4   		, " 
		_cQuery += "    F2.F2_VEND5        AS F2_VEND5   		, " 
        _cQuery += "    SUM(D2.D2_ICMSRET) AS ICMSRET          , " 			
		_cQuery += "    SUM((E1.E1_SALDO + E1.E1_SDACRES - E1_SDDECRE) * (D2.D2_TOTAL / F2.F2_VALMERC)) AS VALTOT           , "
		_cQuery += "    SUM(D2.D2_COMIS1 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
        _cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS1 , "
		_cQuery += "    SUM(D2.D2_COMIS2 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS2 , "
		_cQuery += "    SUM(D2.D2_COMIS3 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS3 , "
		_cQuery += "    SUM(D2.D2_COMIS4 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS4 , "
        _cQuery += "    SUM(D2.D2_COMIS5 * ( E1.E1_SALDO + E1.E1_SDACRES  - E1_SDDECRE - "
		_cQuery += " (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' )"
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC) / 100 ) AS COMIS5 , "
        _cQuery += "    SUM((E1.E1_SALDO + E1.E1_SDACRES - E1_SDDECRE - "
		_cQuery += "  (SELECT SUM(SD2.D2_ICMSRET) FROM " + RETSQLNAME("SD2") + " SD2 WHERE SD2.D2_FILIAL = E1.E1_FILIAL AND SD2.D2_DOC = E1.E1_NUM AND SD2.D2_SERIE   = E1.E1_PREFIXO AND SD2.D2_CLIENTE = E1.E1_CLIENTE AND SD2.D2_LOJA = E1.E1_LOJA AND SD2.D_E_L_E_T_ = ' ' ) "		
		_cQuery += ") * (D2.D2_TOTAL / F2.F2_VALMERC)) AS BASECOMIS "
		_cQuery += "    FROM " + RetSqlName("SE1") + " E1 "
	    _cQuery += "    INNER JOIN " + RetSqlName("SF2") + " F2 "
	    _cQuery += "    ON "
	    _cQuery += "    F2.F2_FILIAL  = E1.E1_FILIAL "
        _cQuery += "    AND F2.F2_DOC     = E1.E1_NUM "
        _cQuery += "    AND (F2.F2_SERIE   = E1.E1_PREFIXO OR E1.E1_PREFIXO = 'R') "
        _cQuery += "    AND F2.F2_CLIENTE = E1.E1_CLIENTE "
        _cQuery += "    AND F2.F2_LOJA    = E1.E1_LOJA "
        _cQuery += "    INNER JOIN " + RetSqlName("SD2") + " D2 "
        _cQuery += "    ON "
	    _cQuery += "    F2.F2_FILIAL      = D2.D2_FILIAL "
        _cQuery += "    AND F2.F2_DOC     = D2.D2_DOC "
        _cQuery += "    AND F2.F2_SERIE  = D2.D2_SERIE "
        _cQuery += "    AND F2.F2_CLIENTE = D2.D2_CLIENTE "
        _cQuery += "    AND F2.F2_LOJA    = D2.D2_LOJA "
		_cQuery += "    WHERE "
		_cQuery += "    E1.D_E_L_E_T_ = ' ' " 
		_cQuery += "    AND F2.D_E_L_E_T_ = ' ' " 
        _cQuery += "    AND E1.E1_TIPO  IN ( 'NF ' , 'ICM' ) "
		_cQuery += "    AND E1.E1_VEND1 <> ' ' "
		_cQuery += "    AND E1.E1_ORIGEM = 'FINA040' "
		_cQuery += "    AND ( ( E1.E1_SALDO + E1.E1_SDACRES ) - E1_SDDECRE ) > 0 "
		_cQuery += "    AND TO_DATE( E1.E1_VENCREA , 'YYYY/MM/DD' ) - TO_DATE('" + DToS(date()) + "' , 'YYYY/MM/DD' ) >= 0 "
        _cQuery +=      _cFilSemBaixa 
        _cQuery += "    GROUP BY F2.F2_FILIAL,F2.F2_DOC, F2.F2_SERIE, F2.F2_EMISSAO, F2.F2_CLIENTE, F2.F2_LOJA, F2.F2_VEND1, F2.F2_VEND2, F2.F2_VEND3, F2.F2_VEND4 , F2.F2_VEND5 "
		_cQuery += "    ORDER BY F2_FILIAL,F2_DOC, F2_SERIE "
 
        If Select(_cAlias) > 0
		   (_cAlias)->( DBCloseArea() )
		EndIf
	
      _cQuery := ChangeQuery(_cQuery)
		
		MPSysOpenQuery( _cQuery , _cAlias ) 

EndCase       

Return  
 
/*
===============================================================================================================================
Programa--------: ROMS025E
Autor-----------: Fabiano Dias
Data da Criacao-: 24/02/2011
Descrição-------: Função que Processa a impressão dos dados do relatório - Baixa Vendedor.
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS025E(oProc As Object) 

Local _cAlias As Character
Local _cAlias3 As Character
Local _nCountRec As Numeric
Local _nTotreg As Numeric
Local _cRazaoCli As Character
Local _cCodGrupo  As Character
Local _cDescGrupo As Character
Local _cMVPAR05 As Character
Local _aVendBonif As Array
Local _cNumeroNf As Character
Local _cSerieNf As Character

Private _aFiliais As Array

_cAlias     := GetNextAlias()
_cAlias3    := GetNextAlias()
_nCountRec  := 0  
_ntotreg    := 0    
_cRazaoCli  := ""
_cCodGrupo  := ""
_cDescGrupo := ""
_cMVPAR05   := MV_PAR06 // Filtro Vendedor 
_aVendBonif := {}
_cNumeroNf  := ""
_cSerieNf   := ""

_aFiliais   := {} 

Begin Sequence
   If Empty(MV_PAR01)
	  U_ITMsg("Favor preencher o parâmetro: Mes/Ano antes de imprimir este relatório.","Atenção",,1)
	  Break 
   EndIf
     
   //=======================================================================================================
   // Chama a rotina para selecao dos registros da comissao.												
   //=======================================================================================================
   FWMsgRun(,{|oproc|ROMS025QRY(_cAlias,1,oproc)},"Aguarde....","Filtrando os dados de credito e debito da comissão.")        
	
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())        
	            	
   //=============================================
   //Armazena o numero de registros encontrados.
   //=============================================
   COUNT TO _nCountRec 
		
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())       
	               	
   //=============================================
   //Verifica se existem registros selecionados.
   //=============================================
   If (_cAlias)->(!Eof())				
      _nni := 0
      
      While (_cAlias)->(!Eof()) 
         _nni++
         oproc:cCaption := ("Processando dados " + StrZero(_nni,10) + " de " +  StrZero(_nCountRec,10))
         ProcessMessages()
         _lachou := .F.

         //================================================
         // Busca dados adicionais
         //================================================
         SF2->(DBSetOrder(1))
         SA3->(DBSetOrder(1))
         If SF2->(DBSeek((_cAlias)->FILIAL+(_cAlias)->NUMERO)) .And. AllTrim((_cAlias)->CODCLI) == AllTrim(SF2->F2_CLIENTE) 
            _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME")
			_cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_GRPVEN")
			_cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
            _ccodrep    := SF2->F2_VEND1
            _cnomerep   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodrep)),SA3->A3_NOME," ")
            _ccodsup    := SF2->F2_VEND4
            _cnomesup   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
            _ccodcoord  := SF2->F2_VEND2
            _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
            _ccodger    := SF2->F2_VEND3
            _cnomeger   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
            _cCodGNac    := SF2->F2_VEND5
            _cNomeGNac   := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNac)),SA3->A3_NOME," ")

            _lachou     := .T.
         Else
            _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias)->CODCLI+(_cAlias)->LOJA,"A1_NOME")
			_cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias)->CODCLI+(_cAlias)->LOJA,"A1_GRPVEN")
			_cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
            _ccodrep    := (_cAlias)->CODVEND
            _cnomerep   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodrep)),SA3->A3_NOME," ")
            _ccodsup    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_SUPE")
            _cnomesup   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
            _ccodcoord  := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_SUPER")
            _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
            _ccodger    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_GEREN")
            _cnomeger   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
            _cCodGNac    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_GERNC")
            _cNomeGNac   := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNac)),SA3->A3_NOME," ")
         EndIf
				
         _ncomsup   := 0
		 _ncomcoord := 0
		 _ncomger   := 0
		 _ncomrep   := 0
		 _nComGNac  := 0
				
		 SE3->(DBSetOrder(1))
		 If SE3->(DBSeek((_cAlias)->FILIAL+(_cAlias)->PREFIXO+(_cAlias)->E3NUMORI+(_cAlias)->PARCELA+(_cAlias)->SEQ))
			While SE3->E3_FILIAL == (_cAlias)->FILIAL .And. ;
			   SE3->E3_PREFIXO == (_cAlias)->PREFIXO .And. ;
			   SE3->E3_NUM == (_cAlias)->E3NUMORI .And. ;
			   SE3->E3_PARCELA == (_cAlias)->PARCELA .And. ;
			   SE3->E3_SEQ == (_cAlias)->SEQ
               
               If SE3->E3_VEND == _ccodrep //Representante
                  _ncomrep := Round(_ncomrep + SE3->E3_COMIS ,3)
               EndIf
			   
			   If SE3->E3_VEND == _ccodsup  //Supervisor
                  _ncomsup := Round(_ncomsup + SE3->E3_COMIS ,3)
               EndIf
               
               If SE3->E3_VEND == _ccodcoord  //Coordenador
                  _ncomcoord := Round(_ncomcoord + SE3->E3_COMIS ,3)
               EndIf

               If SE3->E3_VEND == _ccodger  //Gerente
                  _ncomger := Round(_ncomger + SE3->E3_COMIS ,3)
               EndIf

	           If SE3->E3_VEND == _cCodGNac  //Gerente Nacional
                  _nComGNac := Round(_nComGNac + SE3->E3_COMIS ,3)
               EndIf
               SE3->(DBSkip())
            EndDo
         EndIf

         _nperrep := Round(_ncomrep/(_cAlias)->BASECOMIS*100,3)
         _nperrep := IIf(_nperrep<0,-1*_nperrep,_nperrep)
				
         _nbasecomis := IIf((_cAlias)->COMISSAO<0,-1*(_cAlias)->BASECOMIS,(_cAlias)->BASECOMIS)
				
         _npersup := Round(_ncomsup/(_cAlias)->BASECOMIS*100,3)
         _npersup := IIf(_npersup<0,-1*_npersup,_npersup)
				
         _npercoo := Round(_ncomcoord/(_cAlias)->BASECOMIS*100,3)
         _npercoo := IIf(_npercoo<0,-1*_npercoo,_npercoo)
				
         _nperger := Round(_ncomger/(_cAlias)->BASECOMIS*100,3)
         _nperger := IIf(_nperger<0,-1*_nperger,_nperger)

         _nPerGNac := Round(_nComGNac/(_cAlias)->BASECOMIS*100,3)
         _nPerGNac := IIf(_nPerGNac<0,-1*_nPerGNac,_nPerGNac)

         _dtemissao := IIf(!Empty((_cAlias)->DTEMISSAO),SToD((_cAlias)->DTEMISSAO),"")
         _dtbaixa := IIf(!Empty((_cAlias)->DTBAIXA),SToD((_cAlias)->DTBAIXA),"")
		                       
		 _cNumeroNf := (_cAlias)->NUMERO
		 _cSerieNf  := (_cAlias)->PARCELA
		 If AllTrim((_cAlias)->TIPO) == "NCC"
		 	_cNumeroNf := (_cAlias)->E3NUMORI
		    _cSerieNf  := (_cAlias)->E3SERORI
         EndIf		 	                                      
		 
         //verifica se tem duplicata
         If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados
            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == _cNumeroNf .And. ;  // _vAux[5]  == (_cAlias)->NUMERO .And. ;
											_vAux[6]  == _cSerieNf .And. ; // _vAux[6]  == (_cAlias)->PARCELA .And. ;
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[37] == (_cAlias)->SEQ  })

		 ElseIf ("N" $ MV_PAR07 .And. "G" $ MV_PAR07 .And.  "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07) .Or. ; // Não imprime vendedor
                ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07)  .Or. ; // Não imprime supervisor
                ("G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07)  .Or. ; // Não imprime Coordenador
                (! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07)  .Or. ; // Não imprime gerente
                ("N" $ MV_PAR07 .And. "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07)           // Não imprime gerente nacional
            
			_npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == _cNumeroNf .And. ;  // _vAux[5]  == (_cAlias)->NUMERO .And. ;
											_vAux[6]  == _cSerieNf .And. ; // _vAux[6]  == (_cAlias)->PARCELA .And. ;
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[33] == (_cAlias)->SEQ })

		 Else
            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == _cNumeroNf .And. ;  // _vAux[5]  == (_cAlias)->NUMERO .And. ;
											_vAux[6]  == _cSerieNf .And. ; // _vAux[6]  == (_cAlias)->PARCELA .And. ;
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[21] == (_cAlias)->SEQ  })
         EndIf

         If _npl == 0 //Só incrementa se não tiver no array 
		    //===============================================
			// Incrementa array para geração de excel
			//===============================================		  	
            If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados 
               aAdd(_aDados,{(_cAlias)->FILIAL	,;	             					  //01
							 (_cAlias)->TIPO,;										  //02
			 				 _dtemissao,;											  //03
			 				 _dtbaixa,;												  //04
			 				 _cNumeroNf,;									          //05  // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									          //06  // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											  //07
							 _cDescGrupo,;											  //08
							 (_cAlias)->CODCLI,;									  //09
							 (_cAlias)->LOJA,;										  //10
							 _cRazaoCli,;											  //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	  //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	  //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	  //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			  //16
							 _ccodrep,;												  //17
							 _cnomerep,;											  //18
							 _ccodsup,;												  //19
							 _cnomesup,;											  //20
							 _ccodcoord,;											  //21
							 _cnomecoord,;											  //22
							 _ccodger,;												  //23
							 _cnomeger,;											  //24
                             _cCodGNac,;                                              //25    
                             _cNomeGNac,;                                             //26
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;			  //27
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			  //28
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;			  //29
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			  //30
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			  //31
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			  //32
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;			  //33
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			  //34
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			  //35
							 U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			  //36
							 (_cAlias)->SEQ,;                                         //37
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
							
            ElseIf "N" $ MV_PAR07 .And. "G" $ MV_PAR07 .And.  "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 //  Não imprime vendedor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05  // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06  // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodsup,;												 //17
							 _cnomesup,;											 //18
							 _ccodcoord,;											 //19
							 _cnomecoord,;											 //20
							 _ccodger,;												 //21
							 _cnomeger,;										     //22
                             _cCodGNac,;                                             //23    
                             _cNomeGNac,;                                            //24
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //23 --> 25 
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			 //24 --> 26 
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		     //25 --> 27 
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			 //26 --> 28
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //27 --> 29
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			 //28 --> 30
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 //31
                             U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 //32 
							 (_cAlias)->SEQ,;                                         //31 --> 33
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})

            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime supervisor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodcoord,;											 //19
							 _cnomecoord,;											 //20
							 _ccodger,;												 //21
							 _cnomeger,;											 //22
                             _cCodGNac,;                                             //23    
                             _cNomeGNac,;                                            //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //23 --> 25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 //24 --> 26
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 //25 --> 27
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 //26 --> 28
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //27 --> 29
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 //28 --> 30
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 //31 
                             U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //33
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})

            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime Coordenador
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodsup,;												 //19
							 _cnomesup,;										     //20
							 _ccodger,;												 //21
							 _cnomeger,;										     //22
                             _cCodGNac,;                                             //23    
                             _cNomeGNac,;                                            //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //23 --> 25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			 //24 --> 26
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //25 --> 27
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			 //26 --> 28
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //27 --> 29
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			 //28 --> 30
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 //31
                             U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //29 --> 33
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})

            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodsup,;												 //19
							 _cnomesup,;										 	 //20
							 _ccodcoord,;											 //21
							 _cnomecoord,;											 //22
                             _cCodGNac,;                                             //23    
                             _cNomeGNac,;                                            //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //23 --> 25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			 //24 --> 26
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //25 --> 27
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			 //26 --> 28
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		 	 //27 --> 29
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			 //28 --> 30
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 //31
                             U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //33
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})

                   ElseIf ! "N" $ MV_PAR07 .And. "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 // Não imprime gerente nacional
                          aAdd(_aDados,{(_cAlias)->FILIAL	,;	             		  //01
							 (_cAlias)->TIPO,;										  //02
			 				 _dtemissao,;											  //03
			 				 _dtbaixa,;												  //04
			 				 _cNumeroNf,;									          //05 
							 _cSerieNf,;									          //06 
							 _cCodGrupo ,;											  //07
							 _cDescGrupo,;											  //08
							 (_cAlias)->CODCLI,;									  //09
							 (_cAlias)->LOJA,;										  //10
							 _cRazaoCli,;											  //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	  //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	  //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	  //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			  //16
							 _ccodrep,;												  //17
							 _cnomerep,;											  //18
							 _ccodsup,;												  //19
							 _cnomesup,;											  //20
							 _ccodcoord,;											  //21
							 _cnomecoord,;											  //22
							 _ccodger,;												  //23
							 _cnomeger,;											  //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				  //25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			  //26
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				  //27
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			  //28
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			  //29
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			  //30
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				  //31
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			  //32
							 (_cAlias)->SEQ,;                                          //33
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
            ElseIf "N" $ MV_PAR07 .And. ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 // imprime apenas gerente nacional.
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							          //01
							 (_cAlias)->TIPO,;										  //02
			 				 _dtemissao,;											  //03
			 				 _dtbaixa,;												  //04
			 				 _cNumeroNf,;									          //05 
							 _cSerieNf,;									          //06 
							 _cCodGrupo ,;											  //07
							 _cDescGrupo,;											  //08
							 (_cAlias)->CODCLI,;									  //09
							 (_cAlias)->LOJA,;										  //10
							 _cRazaoCli,;											  //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	  //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	  //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	  //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			  //16
					         _cCodGNac,;                                              //17
                             _cNomeGNac,;                   						  //18
					         U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			  //19
                             U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			  //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
//-----------------------------------------------------------------------------------------------							 
            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 //  imprime apenas gerente
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodger,;												 //17
							 _cnomeger,;											 //18
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //19
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador
           	   aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodcoord,;											 //17
							 _cnomecoord,;											 //18
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 //19
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07  .And. ! "N" $ MV_PAR07 // imprime apenas supervisor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),;//13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodsup,;												 //17
							 _cnomesup,;											 //18
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //19
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;						             //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 _cNumeroNf,;									 //05 // (_cAlias)->NUMERO,;									 //05
							 _cSerieNf,;									 //06 // (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),;//13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //19
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(VALDCT),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
            Else // Não exibe dados do relatório em excel.
               _aDados := {}		
            EndIf							  	
		 EndIf

		 //=======================================================================================================
		 // Chama a rotina para selecao dos registros da comissao.												
		 //=======================================================================================================
		 _nTotReg := 0
		 
		 If aScan(_aVendBonif, (_cAlias)->CODVEND) == 0 //aScan(_aVendBonif, MV_PAR06) == 0  // A Query da bonificação deve ser rodada apenas uma vez por vendedor
		    //aAdd(_aVendBonif, MV_PAR06)
		    aAdd(_aVendBonif, (_cAlias)->CODVEND)
		    MV_PAR06 := (_cAlias)->CODVEND   // Filtro codigo do Vendedor 
		    FWMsgRun(,{|oproc|ROMS025QRY(_cAlias3,3,oproc)},"Aguarde....","Filtrando os dados bonificação.")    
		 		
  		    DBSelectArea(_cAlias3)
		    (_cAlias3)->( DBGoTop() )
		    (_cAlias3)->( DBEval( {|| _nTotReg++ } ) )
		    (_cAlias3)->( DBGoTop() )
         EndIf
         
		 If _nTotReg > 0
			_nConAux := 0
			While (_cAlias3)->( !Eof() )
			   _nConAux++
			   oproc:cCaption := 'Processando bonificações... ['+ StrZero(_nConAux,9) +'] de ['+ StrZero(_nTotReg,9) +'].'
			   ProcessMessages()

 			   _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias3)->F2_CLIENTE+(_cAlias3)->F2_LOJA,"A1_NOME")
			   _cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias3)->F2_CLIENTE+(_cAlias3)->F2_LOJA,"A1_GRPVEN")
			   _cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
			   _cCodVen := (_cAlias3)->F2_VEND1
			   _ccodsup :=  (_cAlias3)->F2_VEND4
			   _cnomesup := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
			   _ccodcoord := (_cAlias3)->F2_VEND2
			   _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
		       _ccodger := (_cAlias3)->F2_VEND3
			   _cnomeger := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
               _cCodGNac := (_cAlias3)->F2_VEND5 
			   _cNomeGNac := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNac)),SA3->A3_NOME," ") 
			   
			   If aScan(_aDados, {|_vAux| _vAux[1]==(_cAlias3)->F2_FILIAL .And. _vAux[2]=="BON" .And. _vAux[5]==(_cAlias3)->F2_DOC}) ==  0
				  // Incrementa array para geração de excel
                  If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                          //01
								   "BON",;													                              //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                  //03
								   "  ",;													                              //04
								   (_cAlias3)->F2_DOC,;									                                  //05
								   "  ",;													                              //06
								   _cCodGrupo ,;											                              //07
								   _cDescGrupo,;											                              //08
								   (_cAlias3)->F2_CLIENTE,;								                                  //09
								   (_cAlias3)->F2_LOJA,;									                              //10
								   _cRazaoCli,;											                                  //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									  //12
							       U_ROMS025I(0,"@E 999,999,999.99"),;													  //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													  //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													  //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							      //16
								   _cCodVen,;												                              //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                              //18
								   _ccodsup,;												                              //19
								   _cnomesup,;												                              //20
								   _ccodcoord,;											                                  //21
								   _cnomecoord,;											                              //22
								   _ccodger,;												                              //23
								   _cnomeger,;												                              //24
                                   _cCodGNac,;                                                                            //25    
                                   _cNomeGNac,;                                                                           //26
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					  //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					  //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.99"),;					  //29-->31
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //30-->32
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					  //31-->33
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //32-->34
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					  //35
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //36
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
							       DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodsup,;												                               //17
								   _cnomesup,;												                               //18
								   _ccodcoord,;											                                   //19
								   _cnomecoord,;											                               //20
								   _ccodger,;												                               //21
								   _cnomeger,;	    										                               //22
								   _cCodGNac,;                                                                             //23    
                                   _cNomeGNac,;                                                                            //24 
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //23-->25 
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //28-->30
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //32
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodcoord,;											                                   //19
								   _cnomecoord,;											                               //20
								   _ccodger,;												                               //21
								   _cnomeger,;												                               //22
								   _cCodGNac,;                                                                             //23    
                                   _cNomeGNac,;                                                                            //24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //32
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07  .And. "N" $ MV_PAR07 // Não imprime Coordenador
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodsup,;												                               //19
								   _cnomesup,;												                               //20
								   _ccodger,;												                               //21
								   _cnomeger,;												                               //22
								   _cCodGNac,;                                                                             //23    
                                   _cNomeGNac,;                                                                            //24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.993"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //28-->30
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //32
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  //-----------------------------------------------------------------------------------
                  ElseIf !"G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente 
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodsup,;												                               //19
								   _cnomesup,;												                               //20
								   _ccodcoord,;											                                   //21
								   _cnomecoord,;											                               //22
								    _cCodGNac,;                                                                            //23    
                                   _cNomeGNac,;                                                                            //24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //32
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
//------------------------------------
                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // Não imprime gerente nacional
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodsup,;												                               //19
								   _cnomesup,;												                               //20
								   _ccodcoord,;											                                   //21
								   _cnomecoord,;											                               //22
								   _ccodger,;												                               //21
								   _cnomeger,;												                               //22
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //32
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})

                  ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas gerente
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodger,;												                               //17
								   _cnomeger,;												                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas Coordenador
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
							       "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodcoord,;											                                   //17
								   _cnomecoord,;											                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas supervisor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                  //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                         //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                               //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodsup,;												                               //17
								   _cnomesup,;												                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //19
				    			   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
					ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas Gerente Nacional
				       aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodGNac,;                                                                             //17    
                                   _cNomeGNac,;                                                                            //18
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;    
                            U_ROMS025I((_cAlias3)->(VALDCT),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->(VLRTITULO-COMPENSACAO),2),"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO)),2)  ,"@E 999,999,999.999"),;
							U_ROMS025I(Round((_cAlias)->((VLRTITULO-COMPENSACAO)-((VLRTITULO-COMPENSACAO)*(VALST/VLRTITULO))),2),"@E 999,999,999.999");
					})
                  Else // Não exibe dados do relatório em excel.
                     _aDados := {}		
                  EndIf
			   EndIf
			   
			   (_cAlias3)->( DBSkip() )
			EndDo
		 EndIf					
		 
		 (_cAlias)->(DBSkip())
		 
	  EndDo
   EndIf

End Sequence

MV_PAR06 := _cMVPAR05   // Filtro Vendedor 

//==========================
//Finaliza o alias criado.
//==========================
DBSelectArea(_cAlias)
(_cAlias)->(DBCloseArea())    

Return 

/*
===============================================================================================================================
Programa--------: ROMS025F
Autor-----------: Julio de Paula Paz
Data da Criacao-: 07/01/2019
Descrição-------: Função que Processa a impressão dos dados do relatório - Baixa Detalhado
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS025F(oProc As Object)
Local _nCountRec As Numeric
Local _ntotreg As Numeric
Local _cRazaoCli As Character
Local _cCodGrupo As Character
Local _cDescGrupo As Character
Local _aLinhaD As Array
Local _aRegDados As Array
Local _cMVPAR05 As Character
Local _aVendBonif  As Array
Local _nI As Numeric
Local _cNumeroNf As Character
Local _cSerieNf As Character
Local _aLinhaAD As Array

Private _aFiliais As Array        
Private _cAlias As Character
Private _cAlias2 As Character
Private _cAlias3 As Character

_nCountRec  := 0  
_ntotreg    := 0    
_cRazaoCli  := ""
_cCodGrupo  := ""
_cDescGrupo := ""
_aLinhaD    := {}
_aRegDados  := {}
_cMVPAR05   := MV_PAR06 // Filtro Vendedor 
_aVendBonif := {}
_nI         := 0
_cNumeroNf  := ""
_cSerieNf   := ""
_aLinhaAD   := {}

_aFiliais   := {}            
_cAlias     := GetNextAlias()
_cAlias2    := GetNextAlias()
_cAlias3    := GetNextAlias()

Begin Sequence

   If Empty(MV_PAR01)
	  U_ITMsg("Favor preencher o parâmetro: Mes/Ano antes de imprimir este relatório.","Atenção",,1)
	  Break 
   EndIf
     
   //=======================================================================================================
   // Chama a rotina para selecao dos registros da comissao.												
   //=======================================================================================================
   FWMsgRun(,{|oproc|ROMS025QRY(_cAlias,1,oproc)},"Aguarde....","Filtrando os dados de credito e debito da comissão.")        
	
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())        
	            	
   //=============================================
   //Armazena o numero de registros encontrados.
   //=============================================
   COUNT TO _nCountRec 
		
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())       
	               	
   //=============================================
   //Verifica se existem registros selecionados.
   //=============================================
   If (_cAlias)->(!Eof())				
      _nni := 0
      
      While (_cAlias)->(!Eof()) 
         _nni++
         oproc:cCaption := ("Processando dados " + StrZero(_nni,10) + " de " +  StrZero(_nCountRec,10))
         ProcessMessages()
         _lachou := .F.

         //================================================
         // Busca dados adicionais
         //================================================
         SF2->(DBSetOrder(1))
         SA3->(DBSetOrder(1))
         If SF2->(DBSeek((_cAlias)->FILIAL+(_cAlias)->NUMERO)) .And. AllTrim((_cAlias)->CODCLI) == AllTrim(SF2->F2_CLIENTE) 
            _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME")
			_cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_GRPVEN")
			_cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
            _ccodrep    := SF2->F2_VEND1
            _cnomerep   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodrep)),SA3->A3_NOME," ")
            _ccodsup    := SF2->F2_VEND4
            _cnomesup   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
            _ccodcoord  := SF2->F2_VEND2
            _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
            _ccodger    := SF2->F2_VEND3
            _cnomeger   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")  
            _cCodGNac    := SF2->F2_VEND5
            _cNomeGNac   := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNac)),SA3->A3_NOME," ")
            _lachou     := .T.
         Else
            _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias)->CODCLI+(_cAlias)->LOJA,"A1_NOME")
			_cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias)->CODCLI+(_cAlias)->LOJA,"A1_GRPVEN")
			_cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
            _ccodrep    := (_cAlias)->CODVEND
            _cnomerep   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodrep)),SA3->A3_NOME," ")
            _ccodsup    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_SUPE")
            _cnomesup   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
            _ccodcoord  := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_SUPER")
            _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
            _ccodger    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_GEREN")
            _cnomeger   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
            _cCodGNac    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_GERNC")
            _cNomeGNac   := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNac)),SA3->A3_NOME," ")
         EndIf
				
         _ncomsup := 0
		 _ncomcoord := 0
		 _ncomger := 0
		 _ncomrep := 0
		 _nComGNac  := 0
				
		 SE3->(DBSetOrder(1))
		 If SE3->(DBSeek((_cAlias)->FILIAL+(_cAlias)->PREFIXO+(_cAlias)->E3NUMORI+(_cAlias)->PARCELA+(_cAlias)->SEQ))
			While SE3->E3_FILIAL == (_cAlias)->FILIAL .And. ;
			   SE3->E3_PREFIXO == (_cAlias)->PREFIXO .And. ;
			   SE3->E3_NUM == (_cAlias)->E3NUMORI .And. ;
			   SE3->E3_PARCELA == (_cAlias)->PARCELA .And. ;
			   SE3->E3_SEQ == (_cAlias)->SEQ
               
               If SE3->E3_VEND == _ccodrep //Representante
                  _ncomrep := Round(_ncomrep + SE3->E3_COMIS ,3)
               EndIf
			   
			   If SE3->E3_VEND == _ccodsup  //Supervisor
                  _ncomsup := Round(_ncomsup + SE3->E3_COMIS ,3)
               EndIf
               
               If SE3->E3_VEND == _ccodcoord  //Coordenador
                  _ncomcoord := Round(_ncomcoord + SE3->E3_COMIS ,3)
               EndIf

               If SE3->E3_VEND == _ccodger  //Gerente
                  _ncomger := Round(_ncomger + SE3->E3_COMIS ,3)
               EndIf

			   If SE3->E3_VEND == _cCodGNac //Gerente Nacional
                  _nComGNac := Round(_nComGNac + SE3->E3_COMIS ,3)
               EndIf

               SE3->(DBSkip())
            EndDo
         EndIf

         _nperrep := Round(_ncomrep/(_cAlias)->BASECOMIS*100,3)
         _nperrep := IIf(_nperrep<0,-1*_nperrep,_nperrep)
				
         _nbasecomis := IIf((_cAlias)->COMISSAO<0,-1*(_cAlias)->BASECOMIS,(_cAlias)->BASECOMIS)
				
         _npersup := Round(_ncomsup/(_cAlias)->BASECOMIS*100,3)
         _npersup := IIf(_npersup<0,-1*_npersup,_npersup)
				
         _npercoo := Round(_ncomcoord/(_cAlias)->BASECOMIS*100,3)
         _npercoo := IIf(_npercoo<0,-1*_npercoo,_npercoo)
				
         _nperger := Round(_ncomger/(_cAlias)->BASECOMIS*100,3)
         _nperger := IIf(_nperger<0,-1*_nperger,_nperger)
		 
         _nPerGNac := Round(_nComGNac/(_cAlias)->BASECOMIS*100,3)
         _nPerGNac := IIf(_nPerGNac<0,-1*_nPerGNac,_nPerGNac)

         _dtemissao := IIf(!Empty((_cAlias)->DTEMISSAO),SToD((_cAlias)->DTEMISSAO),"")
         _dtbaixa := IIf(!Empty((_cAlias)->DTBAIXA),SToD((_cAlias)->DTBAIXA),"")
			
		 _cNumeroNf := (_cAlias)->NUMERO
		 _cSerieNf  := (_cAlias)->PARCELA
		 If AllTrim((_cAlias)->TIPO) == "NCC"
		 	_cNumeroNf := (_cAlias)->E3NUMORI
		    _cSerieNf  := (_cAlias)->E3SERORI
         EndIf		 	                                      

         //verifica se tem duplicata
         If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados // 1
           _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == _cNumeroNf .And. ; // (_cAlias)->NUMERO .And. ;
											_vAux[6]  == _cSerieNf .And. ; // (_cAlias)->PARCELA
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[47] == (_cAlias)->SEQ})

         ElseIf ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime vendedor   
                ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime supervisor 
                ("G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime Coordenador 
                (! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime gerente 
                ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07)        // Não imprime gerente nacional 
										
            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == _cNumeroNf .And. ; // (_cAlias)->NUMERO .And. ;
											_vAux[6]  == _cSerieNf .And. ; // (_cAlias)->PARCELA
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[41] == (_cAlias)->SEQ})
         Else

            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == _cNumeroNf .And. ; // (_cAlias)->NUMERO .And. ;
											_vAux[6]  == _cSerieNf .And. ; // (_cAlias)->PARCELA
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[23] == (_cAlias)->SEQ})

         EndIf

         If _npl == 0 //Só incrementa se não tiver no array
		    //===============================================
			// Incrementa array para geração de excel
			//===============================================		  	
            If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados  // 1
               _aLinhaD:= {(_cAlias)->FILIAL	,;	             					 // 01
						   (_cAlias)->TIPO,;										 // 02
			 			   _dtemissao,;											     // 03
			 			   _dtbaixa,;												 // 04
			 			   _cNumeroNf,;									             // 05  (_cAlias)->NUMERO,;
						   _cSerieNf,;									             // 06  // (_cAlias)->PARCELA
						   _cCodGrupo ,;											 // 07
						   _cDescGrupo,;											 // 08
						   (_cAlias)->CODCLI,;									     // 09
						   (_cAlias)->LOJA,;										 // 10
						   _cRazaoCli,;											     // 11
						   (_cAlias)->VLRTITULO,;	                                 // 12
						   (_cAlias)->COMPENSACAO,;                                  // 13
						   U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
						   (_cAlias)->BAIXASANT,;	                                 // 15
						   U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	 // 16
						   _ccodrep,;												 // 17
						   _cnomerep,;											     // 18
						   _ccodsup,;												 // 19
						   _cnomesup,;											     // 20
						   _ccodcoord,;											     // 21
						   _cnomecoord,;											 // 22
						   _ccodger,;												 // 23
						   _cnomeger,;											     // 24
                           _cCodGNac,;                                               // 25 
						   _cNomeGNac,;                                              // 26
						   U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				  // 25-->27
						   U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				  // 26-->28
                           U_ROMS025I(0,"@E 999,999,999.999"),;                        // 27-->29   "% Com Nota Rep",;          
						   U_ROMS025I(0,"@E 999,999,999.999"),;                        // 28-->30   "Media % Sistemica Rep",;   
						   U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				  // 29-->31   "Vlr Com Sup"	,;	
						   U_ROMS025I(_npersup,"@E 999,999,999.999"),;				  // 30-->32   "% Com Sup"	
                           U_ROMS025I(0,"@E 999,999,999.999"),;                        // 31-->33   "% Com Nota Sup"
						   U_ROMS025I(0,"@E 999,999,999.999"),;                        // 32-->34   "Media % Sistemica Sup"
						   U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			      // 33-->35   "Vlr Com Cood"
						   U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				  // 34-->36   "% Com Cood"
                           U_ROMS025I(0,"@E 999,999,999.999"),;                        // 35-->37   "% Com Nota Coord" 
						   U_ROMS025I(0,"@E 999,999,999.999"),;                        // 36-->38   "Media % Sistemica Coord"
						   U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				  // 37-->39   "Vlr Com Ger"
						   U_ROMS025I(_nperger,"@E 999,999,999.999"),;				  // 38-->40   "% Com Ger"	
                           U_ROMS025I(0,"@E 999,999,999.999"),;                        // 39-->41   "% Com Nota Ger"
						   U_ROMS025I(0,"@E 999,999,999.999"),;                        // 40-->42   "Media % Sistemica Ger"
                           U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;				  // 43  "Vlr Com Ger Nac"
						   U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;				  // 44  "% Com Ger Nac"	
                           U_ROMS025I(0,"@E 999,999,999.999"),;                        // 45  "% Com Nota Ger Nac"
						   U_ROMS025I(0,"@E 999,999,999.999"),;                        // 46  "Media % Sistemica Ger Nac"
						   (_cAlias)->SEQ;                                            // 41-->47  "Sequenc.Comissão"
						   }
                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07//  Não imprime vendedor // 2
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05 // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06 // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;   // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	 // 16
							 _ccodsup,;												 // 17
							 _cnomesup,;											 // 18
							 _ccodcoord,;											 // 19
							 _cnomecoord,;											 // 20
							 _ccodger,;												 // 21
							 _cnomeger,;										     // 22
                             _cCodGNac,;                                             // 23
						     _cNomeGNac,;                                            // 24
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 // 23-->25
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 // 24-->26
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 25-->27  "% Com Nota Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 26-->28  "Media % Sistemica Sup"							 
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		     // 27-->29  "Vlr Com Cood"	
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 // 28-->30  "% Com Cood"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 29-->31  "% Com Nota Coord"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 30-->32  "Media % Sistemica Coord"							 
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 // 31-->33  "Vlr Com Ger"
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 // 32-->34  "% Com Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 33-->35  "% Com Nota Ger"  
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 34-->36  "Media % Sistemica Ger" 							 
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 // 37  "Vlr Com Ger Nac"
						     U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 // 38  "% Com Ger Nac"	
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 39  "% Com Nota Ger Nac"
						     U_ROMS025I(0,"@E 999,999,999.999"),;                     // 40  "Media % Sistemica Ger Nac"
							 (_cAlias)->SEQ;                                         // 35-->41  "Sequenc.Comissão"
							}
                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor // 3
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									 // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									 // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	   // 16
							 _ccodrep,;												 // 17
							 _cnomerep,;											 // 18
							 _ccodcoord,;											 // 19
							 _cnomecoord,;											 // 20
							 _ccodger,;												 // 21
							 _cnomeger,;											 // 22
                             _cCodGNac,;                                             // 23
                             _cNomeGNac,;                                            // 24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 // 23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 // 24-->26
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 25-->27  "% Com Nota Rep"
							 U_ROMS025I(0,"@E 999,999,999.999"),;                     // 26-->28  "Media % Sistemica Rep"
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 // 27-->29  "Vlr Com Cood"
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 // 28-->30  "% Com Cood"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 29-->31  "% Com Nota Coord"
							 U_ROMS025I(0,"@E 999,999,999.999"),;                     // 30-->32  "Media % Sistemica Coord"
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 // 31-->33  "Vlr Com Ger"
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 // 32-->34  "% Com Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 33-->35  "% Com Nota Ger"
							 U_ROMS025I(0,"@E 999,999,999.999"),;                     // 34-->36  "Media % Sistemica Ger"
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 // 37  "Vlr Com Ger Nac"
						     U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 // 38  "% Com Ger Nac"	
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 39  "% Com Nota Ger Nac"
						     U_ROMS025I(0,"@E 999,999,999.999"),;                     // 40  "Media % Sistemica Ger Nac"
							 (_cAlias)->SEQ;                                         // 35-->41  "Sequenc.Comissão"
							 }
                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime Coordenador // 4 
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,; 
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	   // 16
							 _ccodrep,;												 // 17
							 _cnomerep,;											 // 18
							 _ccodsup,;												 // 19
							 _cnomesup,;										     // 20
							 _ccodger,;												 // 21
							 _cnomeger,;										     // 22
                             _cCodGNac,;                                             // 23
						     _cNomeGNac,;                                            // 24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 // 23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 // 24-->26
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 25-->27  "% Com Nota Rep"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 26-->28  "Media % Sistemica Rep"							 
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 // 27-->29  "Vlr Com Sup"
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 // 28-->30  "% Com Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 29-->31  "% Com Nota Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 30-->32  "Media % Sistemica Sup							 
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 // 31-->33  "Vlr Com Ger"
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 // 32-->34  "% Com Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 33-->35  "% Com Nota Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 34-->36  "Media % Sistemica Ger"
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 // 37  "Vlr Com Ger Nac"
						     U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 // 38  "% Com Ger Nac"	
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 39  "% Com Nota Ger Nac"
						     U_ROMS025I(0,"@E 999,999,999.999"),;                     // 40  "Media % Sistemica Ger Nac"
							 (_cAlias)->SEQ;                                         // 35-->41  "Sequenc.Comissão"
							} 

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime gerente // 5
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	   // 16
							 _ccodrep,;												 // 17
							 _cnomerep,;											 // 18
							 _ccodsup,;												 // 19
							 _cnomesup,;										 	 // 20
							 _ccodcoord,;											 // 21
							 _cnomecoord,;											 // 22
                             _cCodGNac,;                                             // 23
                             _cNomeGNac,;                                            // 24 
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 // 23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 // 24-->26
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 25-->27  "% Com Nota Rep"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 26-->28  "Media % Sistemica Rep"							 
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 // 27-->29  "Vlr Com Sup" 
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 // 28-->30  "% Com Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 29-->31  "% Com Nota Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 30-->32  "Media % Sistemica Sup"							 
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		 	 // 31-->33  "Vlr Com Cood"
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 // 32-->34  "% Com Cood"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 33-->35  "% Com Nota Coord"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 34-->36  "Media % Sistemica Coord"
                             U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 // 37  "Vlr Com Ger Nac"
						     U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 // 38  "% Com Ger Nac"	
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 39  "% Com Nota Ger Nac"
						     U_ROMS025I(0,"@E 999,999,999.999"),;                     // 40  "Media % Sistemica Ger Nac" 
							 (_cAlias)->SEQ;                                         // 35-->41  "Sequenc.Comissão"
							 }

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// Não imprime gerente nacional // 5
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	     // 16
							 _ccodrep,;												 // 17
							 _cnomerep,;											 // 18
							 _ccodsup,;												 // 19
							 _cnomesup,;										 	 // 20
							 _ccodcoord,;											 // 21
							 _cnomecoord,;											 // 22
                             _ccodger,;												 // 23
							 _cnomeger,;										     // 24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 // 23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 // 24-->26
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 25-->27  "% Com Nota Rep"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 26-->28  "Media % Sistemica Rep"							 
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 // 27-->29  "Vlr Com Sup" 
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 // 28-->30  "% Com Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 29-->31  "% Com Nota Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 30-->32  "Media % Sistemica Sup"							 
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		 	 // 31-->33  "Vlr Com Cood"
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 // 32-->34  "% Com Cood"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 33-->35  "% Com Nota Coord"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 34-->36  "Media % Sistemica Coord"
                             U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 // 37  "Vlr Com Ger"
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 // 38  "% Com Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 39  "% Com Nota Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 40  "Media % Sistemica Ger"
							 (_cAlias)->SEQ;                                         // 35-->41  "Sequenc.Comissão"
							 }

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }

            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07// imprime apenas gerente nacional
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;		// 16
							 _cCodGNac,;                                             // 17
                             _cNomeGNac,;                                            // 18 
							 U_ROMS025I(_nComGNac,"@E 999,999,999.999"),;			 // 19  "Vlr Com Ger Nac"
						     U_ROMS025I(_nPerGNac,"@E 999,999,999.999"),;			 // 20  "% Com Ger Nac"	
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 21  "% Com Nota Ger Nac"
						     U_ROMS025I(0,"@E 999,999,999.999"),;                     // 22  "Media % Sistemica Ger Nac" 							 
							 (_cAlias)->SEQ;                                         // 23  "Sequenc.Comissão"
							}  

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas gerente // 6
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	  // 16
							 _ccodger,;												 // 17
							 _cnomeger,;											 // 18
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 // 19
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 // 20
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 21 "% Com Nota Ger"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 22 "Media % Sistemica Ger" 							 
							 (_cAlias)->SEQ;                                         // 23 "Sequenc.Comissão"
							}
                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador // 7
           	   _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;   // 16
							 _ccodcoord,;											 // 17
							 _cnomecoord,;											 // 18
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 // 19
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 // 20
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 21 "% Com Nota Coord"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 22 "Media % Sistemica Coord"							 
							 (_cAlias)->SEQ;                                         // 23 "Sequenc.Comissão"
							}

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas supervisor // 8
               _aLinhaD :=  {(_cAlias)->FILIAL	,;							         // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	   // 16
							 _ccodsup,;												 // 17
							 _cnomesup,;											 // 18
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 // 19
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 // 20
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 21 "% Com Nota Sup"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 22 "Media % Sistemica Sup"							 
							 (_cAlias)->SEQ;                                         // 23 "Sequenc.Comissão"
							}		

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }				
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor // 9 
               _aLinhaD :=  {(_cAlias)->FILIAL	,;						             // 01
							 (_cAlias)->TIPO,;										 // 02
			 				 _dtemissao,;											 // 03
			 				 _dtbaixa,;												 // 04
			 				 _cNumeroNf,;									         // 05  // (_cAlias)->NUMERO,;
							 _cSerieNf,;									         // 06  // (_cAlias)->PARCELA
							 _cCodGrupo ,;											 // 07
							 _cDescGrupo,;											 // 08
							 (_cAlias)->CODCLI,;									 // 09
							 (_cAlias)->LOJA,;										 // 10
							 _cRazaoCli,;											 // 11
							 (_cAlias)->VLRTITULO,;	                                 // 12
							 (_cAlias)->COMPENSACAO,;                                // 13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 // 14
							 (_cAlias)->BAIXASANT,;	                                 // 15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),; //_nbasecomis,;	 // 16
							 _ccodrep,;												 // 17
							 _cnomerep,;											 // 18
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 // 19
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 // 20
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 21 "% Com Nota Rep"
                             U_ROMS025I(0,"@E 999,999,999.999"),;                     // 22 "Media % Sistemica Rep"							 
							 (_cAlias)->SEQ;                                         // 23 "Sequenc.Comissão"
							}					

                     _aLinhaAD :=  { U_ROMS025I((_cAlias)->VALDCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  		
                     }
            Else // Não exibe dados do relatório em excel.
              _aLinhaD :=  {}		
              _aDados  := {}
            EndIf							  	
		 EndIf
         
         If ! Empty(_aLinhaD)                                                    
                                        //      1               2                  3                 4                  5                 6             7         
            //_aRegDados := ROMS025G(_aLinhaD, (_cAlias)->FILIAL, (_cAlias)->NUMERO, (_cAlias)->SERIE, (_cAlias)->CODCLI, (_cAlias)->LOJA,(_cAlias)->TIPO)
            _aRegDados := ROMS025G(_aLinhaD, (_cAlias)->FILIAL, (_cAlias)->NUMERO, (_cAlias)->SERIE, (_cAlias)->CODCLI, (_cAlias)->LOJA,(_cAlias)->TIPO,_aLinhaAD)
            
            For _nI := 1 To Len(_aRegDados)
                aAdd(_aDados, AClone(_aRegDados[_nI]))
            Next

			_aLinhaD :=  {}	
         EndIf

		 //=======================================================================================================
		 // Chama a rotina para selecao dos registros da comissao.												
		 //=======================================================================================================
		 MV_PAR06 := (_cAlias)->CODVEND  // Filtro codigo do Vendedor 
		 
		 _nTotReg := 0 
		 
		 If aScan(_aVendBonif, MV_PAR06) == 0  // A Query da bonificação deve ser rodada apenas uma vez por vendedor
		    aAdd(_aVendBonif, MV_PAR06)
		    
		    FWMsgRun(,{|oproc|ROMS025QRY(_cAlias3,3,oproc)},"Aguarde....","Filtrando os dados bonificação.")    
		 		
  		    DBSelectArea(_cAlias3)
		    (_cAlias3)->( DBGoTop() )
		    (_cAlias3)->( DBEval( {|| _nTotReg++ } ) )
		    (_cAlias3)->( DBGoTop() )
         EndIf
         
         If _nTotReg > 0
			_nConAux := 0
			While (_cAlias3)->( !Eof() )
			   _nConAux++
			   oproc:cCaption := 'Processando bonificações... ['+ StrZero(_nConAux,9) +'] de ['+ StrZero(_nTotReg,9) +'].'
			   ProcessMessages()

 			   _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias3)->F2_CLIENTE+(_cAlias3)->F2_LOJA,"A1_NOME")
			   _cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias3)->F2_CLIENTE+(_cAlias3)->F2_LOJA,"A1_GRPVEN")
			   _cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
			   _cCodVen := (_cAlias3)->F2_VEND1
			   _ccodsup :=  (_cAlias3)->F2_VEND4
			   _cnomesup := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
			   _ccodcoord := (_cAlias3)->F2_VEND2
			   _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
		       _ccodger := (_cAlias3)->F2_VEND3
			   _cnomeger := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")

			   _cCodGNac := (_cAlias3)->F2_VEND5
               _cNomeGNac := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
			   
			   If aScan(_aDados, {|_vAux| _vAux[1]==(_cAlias3)->F2_FILIAL .And. _vAux[2]=="BON" .And. _vAux[5]==(_cAlias3)->F2_DOC}) ==  0
				  // Incrementa array para geração de excel
                  If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 ) // Imprime todos os dados  // 1
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                          // 01
								   "BON",;													                              // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                  // 03
								   "  ",;													                              // 04
								   (_cAlias3)->F2_DOC,;									                                  // 05
								   "  ",;													                              // 06
								   _cCodGrupo ,;											                              // 07
								   _cDescGrupo,;											                              // 08
								   (_cAlias3)->F2_CLIENTE,;								                                  // 09
								   (_cAlias3)->F2_LOJA,;									                              // 10
								   _cRazaoCli,;											                                  // 11
								   (_cAlias3)->VALTOT,;									                                  // 12
							       0,;													                                  // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													  // 14
								   0,;													                                  // 15
								   (_cAlias3)->VALTOT*-1,;							                                      // 16
								   _cCodVen,;												                              // 17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                              // 18
								   _ccodsup,;												                              // 19
								   _cnomesup,;												                              // 20
								   _ccodcoord,;											                                  // 21
								   _cnomecoord,;											                              // 22
								   _ccodger,;												                              // 23
								   _cnomeger,;												                              // 24
                                   _cCodGNac,;                                                                            // 25
                                   _cNomeGNac,;                                                                           // 26 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					  // 25-->27 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  // 26-->28 
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 27-->29  "% Com Nota Rep"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 28-->30  "Media % Sistemica Rep"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					  // 29-->31  "Vlr Com Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  // 30-->32  "% Com Sup"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 31-->33  "% Com Nota Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 32-->34  "Media % Sistemica Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					  // 33-->35  "Vlr Com Cood"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  // 34-->36  "% Com Cood"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 35-->37  "% Com Nota Coord"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 36-->38  "Media % Sistemica Coord"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					  // 37-->39  "Vlr Com Ger"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  // 38-->40  "% Com Ger"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 39-->41  "% Com Nota Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 40-->42  "Media % Sistemica Ger"
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					  // 43 "Vlr Com Ger Nac"
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  // 44 "% Com Ger Nac"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 45 "% Com Nota Ger Nac"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                    // 46 "Media % Sistemica Ger Nac"
								   " ";                                                                                   // 41-->47  "Sequenc.Comissão"
								   }                           
							_aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor  // 2
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
							       DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _ccodsup,;												                               // 17
								   _cnomesup,;												                               // 18
								   _ccodcoord,;											                                   // 19
								   _cnomecoord,;											                               // 20
								   _ccodger,;												                               // 21
								   _cnomeger,;												                               // 22
                                   _cCodGNac,;                                                                             // 23
                                   _cNomeGNac,;                                                                            // 24 
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   // 23-->25 
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 24-->26 
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 25-->27   "% Com Nota Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 26-->28   "Media % Sistemica Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   // 27-->29   "Vlr Com Cood"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 28-->30   "% Com Cood"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 29-->31   "% Com Nota Coord"   
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 30-->32   "Media % Sistemica Coord" 
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   // 31-->33   "Vlr Com Ger"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 32-->34   "% Com Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 33-->35   "% Com Nota Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 34-->36   "Media % Sistemica Ger"
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   // 37  "Vlr Com Ger Nac"
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 38  "% Com Ger Nac"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 39  "% Com Nota Ger Nac"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 40  "Media % Sistemica Ger Nac"
								   " ";                                                                                    // 35-->41  "Sequenc.Comissão"
							       }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor // 3
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _cCodVen,;												                               // 17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               // 18
								   _ccodcoord,;											                                   // 19
								   _cnomecoord,;											                               // 20
								   _ccodger,;												                               // 21
								   _cnomeger,;												                               // 22
                                   _cCodGNac,;                                                                             // 23
                                   _cNomeGNac,;                                                                            // 24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   // 23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 24-->26 
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 25-->27   "% Com Nota Rep"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 26-->28   "Media % Sistemica Rep"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   // 27-->29   "Vlr Com Cood"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 28-->30   "% Com Cood"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 29-->31   "% Com Nota Coord"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 30-->32   "Media % Sistemica Coord"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   // 31-->33   "Vlr Com Ger"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 32-->34   "% Com Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 33-->35   "% Com Nota Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 34-->36   "Media % Sistemica Ger"
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   // 37 "Vlr Com Ger Nac"
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 38 "% Com Ger Nac"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 39 "% Com Nota Ger Nac"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 40 "Media % Sistemica Ger Nac"
								   " ";                                                                                    // 35-->41  "Sequenc.Comissão"
							 	   }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime Coordenador  // 4 
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;												       // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _cCodVen,;												                               // 17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               // 18
								   _ccodsup,;												                               // 19
								   _cnomesup,;												                               // 20
								   _ccodger,;												                               // 21
								   _cnomeger,;												                               // 22
                                   _cCodGNac,;                                                                             // 23
                                   _cNomeGNac,;                                                                            // 24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   // 23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 24-->26
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 25-->27  "% Com Nota Rep"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 26-->28  "Media % Sistemica Rep"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   // 27-->29  "Vlr Com Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 28-->30  "% Com Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 29-->31  "% Com Nota Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 30-->32  "Media % Sistemica Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   // 31-->33  "Vlr Com Ger"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 32-->34  "% Com Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 33-->35  "% Com Nota Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 34-->36  "Media % Sistemica Ger"
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   // 37 "Vlr Com Ger Nac"
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 38 "% Com Ger Nac"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 39 "% Com Nota Ger Nac"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 40 "Media % Sistemica Ger Nac"
								   " ";                                                                                    // 35-->41  "Sequenc.Comissão"
								   }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime gerente  // 5
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _cCodVen,;												                               // 17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               // 18
								   _ccodsup,;												                               // 19
								   _cnomesup,;												                               // 20
								   _ccodcoord,;											                                   // 21
								   _cnomecoord,;											                               // 22
                                   _cCodGNac,;                                                                             // 23
                                   _cNomeGNac,;                                                                            // 24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   // 23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 24-->26
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 25-->27  "% Com Nota Rep"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 26-->28  "Media % Sistemica Rep"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   // 27-->29  "Vlr Com Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 28-->30  "% Com Sup"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 29-->31  "% Com Nota Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 30-->32  "Media % Sistemica Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   // 31-->33  "Vlr Com Cood"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 32-->34  "% Com Cood"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 33-->35  "% Com Nota Coord" 
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 34-->36  "Media % Sistemica Coord"
                                   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   // 37 "Vlr Com Ger Nac"
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 38 "% Com Ger Nac"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 39 "% Com Nota Ger Nac"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 40 "Media % Sistemica Ger Nac"
								   " ";                                                                                    // 35-->41 "Sequenc.Comissão"
								   }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // Não imprime gerente Nacional // 5
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _cCodVen,;												                               // 17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               // 18
								   _ccodsup,;												                               // 19
								   _cnomesup,;												                               // 20
								   _ccodcoord,;											                                   // 21
								   _cnomecoord,;											                               // 22
								   _ccodger,;												                               // 23
								   _cnomeger,;												                               // 24
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   // 23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 24-->26
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 25-->27  "% Com Nota Rep"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 26-->28  "Media % Sistemica Rep"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   // 27-->29  "Vlr Com Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 28-->30  "% Com Sup"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 29-->31  "% Com Nota Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 30-->32  "Media % Sistemica Sup"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   // 31-->33  "Vlr Com Cood"
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 32-->34  "% Com Cood"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 33-->35  "% Com Nota Coord" 
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 34-->36  "Media % Sistemica Coord"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   // 37  "Vlr Com Ger"
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 38  "% Com Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 39  "% Com Nota Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 40  "Media % Sistemica Ger"
								   " ";                                                                                    // 35-->41  "Sequenc.Comissão"
								   } 
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas gerente nacional
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _cCodGNac,;                                                                             // 17
                                   _cNomeGNac,;                                                                            // 18 
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   // 19 "Vlr Com Ger Nac"
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 20 "% Com Ger Nac"	
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 21 "% Com Nota Ger Nac"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 22 "Media % Sistemica Ger Nac"
								   " ";                                                                                    // 23 "Sequenc.Comissão"
							    	}
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas gerente // 6
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _ccodger,;												                               // 17
								   _cnomeger,;												                               // 18
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   // 19
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 20
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 21 "% Com Nota Ger"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 22 "Media % Sistemica Ger"
								   " ";                                                                                    // 23 "Sequenc.Comissão"
							    	}
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador // 7
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
							       "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _ccodcoord,;											                                   // 17
								   _cnomecoord,;											                               // 18
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   // 19
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 20
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 21 "% Com Nota Coord"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 22 "Media % Sistemica Coord"
								   " ";                                                                                    // 23 "Sequenc.Comissão"
								   }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas supervisor // 8 
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _ccodsup,;												                               // 17
								   _cnomesup,;												                               // 18
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   // 19
				    			   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 20
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 21 "% Com Nota Sup"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 22 "Media % Sistemica Sup"
								   " ";                                                                                    // 23 "Sequenc.Comissão"
								   }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor // 9 
				     _aLinhaD :=  {(_cAlias3)->F2_FILIAL	,;					                                           // 01
								   "BON",;													                               // 02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   // 03
								   "  ",;													                               // 04
								   (_cAlias3)->F2_DOC,;									                                   // 05
								   "  ",;													                               // 06
								   _cCodGrupo ,;											                               // 07
								   _cDescGrupo,;											                               // 08
								   (_cAlias3)->F2_CLIENTE,;								                                   // 09
								   (_cAlias3)->F2_LOJA,;									                               // 10
								   _cRazaoCli,;											                                   // 11
								   (_cAlias3)->VALTOT,;									                                   // 12
								   0,;													                                   // 13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   // 14
								   0,;													                                   // 15
								   (_cAlias3)->VALTOT*-1,;							                                       // 16
								   _cCodVen,;												                               // 17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               // 18
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   // 19
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   // 20
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 21 "% Com Nota Rep"
                                   U_ROMS025I(0,"@E 999,999,999.999"),;                                                     // 22 "Media % Sistemica Rep"
								   " ";                                                                                    // 23 "Sequenc.Comissão"
							 	   }
                           _aLinhaAD :=  { U_ROMS025I((_cAlias3)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  		
                           }
                  Else // Não exibe dados do relatório em excel.
                     _aLinhaD := {}		
                     _aDados  := {}
                  EndIf
			   EndIf

			   If ! Empty(_aLinhaD)
                  _aRegDados := ROMS025G(_aLinhaD, (_cAlias3)->F2_FILIAL, (_cAlias3)->F2_DOC, (_cAlias3)->F2_SERIE, (_cAlias3)->F2_CLIENTE, (_cAlias3)->F2_LOJA,"BON",_aLinhaAD)
            
                  For _nI := 1 To Len(_aRegDados)
                      aAdd(_aDados, AClone(_aRegDados[_nI]))
                  Next

				  _aLinhaD :=  {}	

               EndIf
			   
			   (_cAlias3)->( DBSkip() )
			EndDo
		 EndIf					
		 
		 (_cAlias)->(DBSkip())
		 
	  EndDo
   EndIf

End Sequence

MV_PAR06 := _cMVPAR05   // Filtro Vendedor 
	
//==========================
//Finaliza o alias criado.
//==========================
DBSelectArea(_cAlias)
(_cAlias)->(DBCloseArea())    

Return 

/*
===============================================================================================================================
Programa--------: ROMS025G
Autor-----------: Julio de Paula Paz
Data da Criacao-: 07/01/2019
Descrição-------: Le e retorna os dados dos itens das notas fiscais.
Parametros------: _aDadosRel = Array com os dados do relatório.
                  _cFilialNF = Filial da nota.
                  _cNRNF     = Numero da nota.
                  _cSerieNf  = Serie da nota.
                  _cCodCli   = Codigo do Cliente.
                  _cLojaCli  = Loja do Cliente.
                  _cTipoDoc  = Tipo de Documento: NF, NCC.                  
Retorno---------: aRet = Array com os dados do relatório mais os dados dos itens da nota fiscal.
===============================================================================================================================
*/                          //1            2                        3                    4                       5                       6                      7                       8
Static Function ROMS025G(_aDadosR As Array, _cFilialNF As Character, _cNRNF As Character, _cSerieNf As Character, _cCodCli As Character, _cLojaCli As Character, _cTipoDoc As Character, _aDadosRAD As Array) As Array
Local _aRet As Array
Local _aLinhaNF As Array
Local _aOrd As Array
Local _nI As Numeric
Local _cDescPrd As Character
Local _aComiss As Array
Local _nComisVend As Numeric
Local _nComisSuper As Numeric
Local _nComisCoord As Numeric
Local _nComisGer As Numeric
Local _nComisGNac As Numeric
Local _nValTotMerc As Numeric
Local _nTotNF As Numeric
Local _nPercItem As Numeric
Local _nFatorBas As Numeric
Local _nMedSisVd As Numeric
Local _nMedSisSp As Numeric
Local _nMedSisCo As Numeric
Local _nMedSisGe As Numeric
Local _nMedSisGN As Numeric
Local _nPerSisVd As Numeric
Local _nPerSisSp As Numeric
Local _nPerSisCo As Numeric
Local _nPerSisGe As Numeric
Local _nPerSisGN As Numeric
Local _nValTotItem As Numeric
Local _cBIMIX As Character
Local i As Numeric

_aRet := {}
_aLinhaNF := {}
_aOrd := SaveOrd({"SD1","SD2","SE1","SF1","SF2"})
_nI:= 0
_cDescPrd := ""
_aComiss := {}
_nComisVend  := 0
_nComisSuper := 0
_nComisCoord := 0
_nComisGer := 0
_nComisGNac := 0
_nValTotMerc := 1 // Inicializado com um para divisão.
_nTotNF := 0
_nPercItem := 0
_nFatorBas := 0
_nMedSisVd := 0
_nMedSisSp := 0
_nMedSisCo := 0
_nMedSisGe := 0
_nMedSisGN := 0
_nPerSisVd := 0
_nPerSisSp := 0
_nPerSisCo := 0
_nPerSisGe := 0
_nPerSisGN := 0
_nValTotItem := 0
_cBIMIX := ""
i := 0

Begin Sequence
   //==========================================================================
   // Nota Fiscal de Devolução - Deve-se localizar a nota fiscal de origem.
   //==========================================================================
   If AllTrim(_cTipoDoc) == "NCC"   // DEVOLUÇÃO
      SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM                                                                                                     
      If SD1->(DBSeek(U_ItKey(_cFilialNF,"D1_FILIAL")+U_ItKey(_cNRNF,"D1_DOC")+U_ItKey(_cSerieNf,"D1_SERIE")+U_ItKey(_cCodCli,"D1_FORNECE")+U_ItKey(_cLojaCli,"D1_LOJA")))
	     SF1->(DBSetOrder(1)) // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO

         While ! SD1->(Eof()) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == U_ItKey(_cFilialNF,"D1_FILIAL")+U_ItKey(_cNRNF,"D1_DOC")+U_ItKey(_cSerieNf,"D1_SERIE")+U_ItKey(_cCodCli,"D1_FORNECE")+U_ItKey(_cLojaCli,"D1_LOJA")
		    SF1->(DBSeek(SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA)))
            _nTotNF := SF1->F1_VALMERC
            _nPercItem := SD1->D1_TOTAL / SF1->F1_VALMERC

            _aLinhaNF := {}
            For _nI := 1 To Len(_aDadosR)
                aAdd(_aLinhaNF, _aDadosR[_nI])
            Next

            _aComiss     := U_ROMS025B(SD1->D1_FILIAL,SD1->D1_DOC,SD1->D1_SERIE,SD1->D1_FORNECE,SD1->D1_LOJA,SD1->D1_COD)
            _nComisVend  := _aComiss[1] // % Comissão Vendedor            - D2_COMIS1
            _nComisCoord := _aComiss[2] // % Comissão Coordenador         - D2_COMIS2
            _nComisGer   := _aComiss[3] // % Comissão Gerente             - D2_COMIS3
            _nComisSuper := _aComiss[4] // % Comissão Supervidor          - D2_COMIS4
            _nValTotMerc := _aComiss[5] // Valor total mercadoria SF2     - F2_VALMERC
            _nValTotItem := _aComiss[6] // Valor Total do item Tabela SD2 - D2_TOTAL
            _nComisGNac  := _aComiss[7] // % Comissão Gerente Nacional    - D2_COMIS5

            If _nValTotMerc == 0
               _nValTotMerc := 1 // Inicializado com 1 para divisão. 
            EndIf

            _nTotNF := _nValTotMerc //SF2->F2_VALMERC 

            _nFatorBas := _aDadosR[16] / _nTotNF

            _nPercItem := _nValTotItem / _nTotNF 
            
            _nMedSisVd := (_nValTotItem * _nComisVend  * _nFatorBas) / 100
			_nMedSisSp := (_nValTotItem * _nComisSuper * _nFatorBas) / 100
			_nMedSisCo := (_nValTotItem * _nComisCoord * _nFatorBas) / 100
			_nMedSisGe := (_nValTotItem * _nComisGer   * _nFatorBas) / 100
            _nMedSisGN := (_nValTotItem * _nComisGNac   * _nFatorBas) / 100
            _nPerSisVd := (_nMedSisVd / _nValTotItem / _nFatorBas) * 100
			_nPerSisSp := (_nMedSisSp / _nValTotItem / _nFatorBas) * 100
			_nPerSisCo := (_nMedSisCo / _nValTotItem / _nFatorBas) * 100
			_nPerSisGe := (_nMedSisGe / _nValTotItem / _nFatorBas) * 100
            _nPerSisGN := (_nMedSisGN / _nValTotItem / _nFatorBas) * 100
            
            If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 ) // Imprime todos os dados  // 1
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // SD1->D1_TOTAL // 12   Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc)  // 13   Compensação  
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14 Desconto do item.	SD1->D1_DESC 						
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // 15 (SD1->D1_TOTAL/_nValTotMerc)             // 15   
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                      // 16 _nbasecomis * _nPercItem        // (SD1->D1_TOTAL/_nValTotMerc)                      // 16   
			   _aLinhaNF[27] := _aLinhaNF[16] * (_nComisVend / 100)                             // 25 -- > 27 
			   _aLinhaNF[28] := _nComisVend                                                     // 26 -- > 28  

			   _aLinhaNF[29] := _nPerSisVd                                                      // "% Com Nota Rep",;          // 27 --> 29
			   _aLinhaNF[30] := _nMedSisVd		                                                // "Media % Sistemica Rep",;   // 28 --> 30

			   _aLinhaNF[31] := _aLinhaNF[16] * (_nComisSuper / 100)                            // 29 --> 31 // "Vlr Com Sup"
			   _aLinhaNF[32] := _nComisSuper	                                                // 30 --> 32 // "% Com Sup"

			   _aLinhaNF[33] := _nPerSisSp                                                      // "% Com Nota Sup",;        // 31 --> 33
			   _aLinhaNF[34] := _nMedSisSp                                                      // "Media % Sistemica Sup",; // 32 --> 34

			   _aLinhaNF[35] := _aLinhaNF[16] * (_nComisCoord / 100)		                    // "Vlr Com Cood" 33 --> 35  
			   _aLinhaNF[36] := _nComisCoord	                                                // "% Com Cood"   34 --> 36  

			   _aLinhaNF[37] := _nPerSisCo                                                      // "% Com Nota Coord",;        // 35 -->37  Calculado
			   _aLinhaNF[38] := _nMedSisCo                                                      // "Media % Sistemica Coord",; // 36 -->38  Calculado 

			   _aLinhaNF[39] := _aLinhaNF[16]  * (_nComisGer / 100)	                            // "Vlr Com Ger"  37 -->39
			   _aLinhaNF[40] := _nComisGer                                                      // "% Com Ger"    38 -->40

               _aLinhaNF[41] := _nPerSisGe                                                      // "% Com Nota Ger",;         39 -->41  Calculado
			   _aLinhaNF[42] := _nMedSisGe                                                      // "Media % Sistemica Ger",;  40 -->42  Calculado			   

               _aLinhaNF[43] := _aLinhaNF[16]  * (_nComisGNac / 100)	                        // "Vlr Com Ger Nac"  
			   _aLinhaNF[44] := _nComisGNac                                                     // "% Com Ger Nac"    

               _aLinhaNF[45] := _nPerSisGN                                                     // "% Com Nota Ger Nac",;         
			   _aLinhaNF[46] := _nMedSisGN                                                     // "Media % Sistemica Ger Nac",;  

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12   Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13   Compensação  
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14   Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15   
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16   
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 25   
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 26   
			   _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    //
			   _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999") 		            // 
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                    // 
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // 
			   _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // 
			   _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // 
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999") 		            // 
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999") 	                // 
			   _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // 
			   _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // 
			   _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999") 	                // 
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // 
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // 
			   _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // 
		       _aLinhaNF[41] := U_ROMS025I(_aLinhaNF[41],"@E 999,999,999.999")                    // 41 
			   _aLinhaNF[42] := U_ROMS025I(_aLinhaNF[42],"@E 999,999,999.999")                    // 42 
			   _aLinhaNF[43] := U_ROMS025I(_aLinhaNF[43],"@E 999,999,999.999") 	                 // 43
			   _aLinhaNF[44] := U_ROMS025I(_aLinhaNF[44],"@E 999,999,999.999")                    // 44
               _aLinhaNF[45] := U_ROMS025I(_aLinhaNF[45],"@E 999,999,999.999")                    // 45
			   _aLinhaNF[46] := U_ROMS025I(_aLinhaNF[46],"@E 999,999,999.999")                    // 46


            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor // 2 
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                       //_aLinhaNF[12]  := SD1->D1_TOTAL                                                   // 12  Valor total do item.	
			   _aLinhaNF[13]  := (_cAlias)->COMPENSACA * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc)            // 13  Compensação
			   _aLinhaNF[14]  := (_cAlias)->DESCONTO  * _nPercItem                               // 14  Desconto do item.	//SD1->D1_DESC						
			   _aLinhaNF[15]  := (_cAlias)->BAIXASANT * _nPercItem                               // (SD1->D1_TOTAL/_nValTotMerc)             // 15  
			   _aLinhaNF[16]  := _aLinhaNF[16] * _nPercItem                                      // _nbasecomis * _nPercItem // (SD1->D1_TOTAL/_nValTotMerc)                      // 16  

			   _aLinhaNF[25]  := _aLinhaNF[16] * (_nComisSuper / 100)                            // 23-->25   
			   _aLinhaNF[26]  := _nComisSuper                                                    // 24-->26  
               _aLinhaNF[27]  := _nPerSisSp                                                      // "% Com Nota Sup",;           25-->27  
               _aLinhaNF[28]  := _nMedSisSp                                                      // "Media % Sistemica Sup",;    26-->28   
			   _aLinhaNF[29]  := _aLinhaNF[16] * (_nComisCoord / 100)                            // "Vlr Com Cood"               27-->29 
			   _aLinhaNF[30]  := _nComisCoord                                                    // "% Com Cood"                 28-->30 
               _aLinhaNF[31]  :=  _nPerSisCo                                                     // "% Com Nota Coord",;         29-->31  
               _aLinhaNF[32]  :=  _nMedSisCo                                                     // "Media % Sistemica Coord",;  30-->32    
			   _aLinhaNF[33]  := _aLinhaNF[16] * (_nComisGer / 100)                              // "Vlr Com Ger"                31-->33  
			   _aLinhaNF[34]  := _nComisGer                                                      // "% Com Ger"		             32-->34 
               _aLinhaNF[35]  :=  _nPerSisGe                                                     // "% Com Nota Ger",;           33-->35   
               _aLinhaNF[36]  :=  _nMedSisGe                                                     // "Media % Sistemica Ger",;    34-->36  

			   _aLinhaNF[37] := _aLinhaNF[16]  * (_nComisGNac / 100)	                         // "Vlr Com Ger Nac"  
			   _aLinhaNF[38] := _nComisGNac                                                      // "% Com Ger Nac"    
               _aLinhaNF[39] := _nPerSisGN                                                       // "% Com Nota Ger Nac",;         
			   _aLinhaNF[40] := _nMedSisGN                                                       // "Media % Sistemica Ger Nac",;  

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.99")                     // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.99")                     // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.99")                     // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.99")                     // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.99")                     // 16  

			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                     // 23-->25  
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                     // 24-->26  
               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                     // "% Com Nota Sup"          25-->27
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                     // "Media % Sistemica Sup"   26-->28 
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                     // "Vlr Com Cood"	           27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                     // "% Com Cood"              28-->30
               _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                     // "% Com Nota Coord"        29-->31 
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                     // "Media % Sistemica Coord" 30-->32   
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                     // "Vlr Com Ger"             31-->33 
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                     // "% Com Ger"		       32-->34
               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                     // "% Com Nota Ger"          33-->35  
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                     // "Media % Sistemica Ger"   34-->36 
			   _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                     // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                     // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                     // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                     // "Media % Sistemica Ger Nac"   


            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor  // 3
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                       // _aLinhaNF[12] := SD1->D1_TOTAL 	                                                // 12 Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                               // (SD1->D1_TOTAL/_nValTotMerc)            // 13 Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                                // 14 Desconto do item.	// SD1->D1_DESC						
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                                // (SD1->D1_TOTAL/_nValTotMerc)             // 15 
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                       // _nbasecomis * _nPercItem // (SD1->D1_TOTAL/_nValTotMerc) 	                    // 16 
			   _aLinhaNF[25] := _aLinhaNF[16] * (_nComisVend / 100) 	                         // 23-->25  
			   _aLinhaNF[26] := _nComisVend	                                                     // 24-->26 
               _aLinhaNF[27] := _nPerSisVd                                                       // "% Com Nota Rep",;          25-->27  
               _aLinhaNF[28] := _nMedSisVd                                                       // "Media % Sistemica Rep",;   26-->28 
			   _aLinhaNF[29] := _aLinhaNF[16] * (_nComisCoord / 100)	                         // "Vlr Com Cood"	,;		    27-->29
			   _aLinhaNF[30] := _nComisCoord	                                                 // "% Com Cood"	,;		    28-->30 
               _aLinhaNF[31] := _nPerSisCo                                                       // "% Com Nota Coord",;        29-->31  
			   _aLinhaNF[32] := _nMedSisCo                                                       // "Media % Sistemica Coord",; 30-->32 
			   _aLinhaNF[33] := _aLinhaNF[16] * (_nComisGer / 100)                               // "Vlr Com Ger"	,;		    31-->33
			   _aLinhaNF[34] :=	_nComisGer                                                       // "% Com Ger"		,;			32-->34
               _aLinhaNF[35] := _nPerSisGe                                                       // "% Com Nota Ger",;          33-->35
               _aLinhaNF[36] := _nMedSisGe                                                       // "Media % Sistemica Ger",;   34-->36
               _aLinhaNF[37] := _aLinhaNF[16]  * (_nComisGNac / 100)	                         // "Vlr Com Ger Nac"  
			   _aLinhaNF[38] := _nComisGNac                                                      // "% Com Ger Nac"    
               _aLinhaNF[39] := _nPerSisGN                                                       // "% Com Nota Ger Nac",;         
			   _aLinhaNF[40] := _nMedSisGN                                                       // "Media % Sistemica Ger Nac",;  			   
			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12 Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13 Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14 Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15 
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999") 	                 // 16 
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[23],"@E 999,999,999.999")                    // 23-->25  
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[24],"@E 999,999,999.999")                    // 24-->26  
               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // "% Com Nota Rep"          25-->27 
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // "Media % Sistemica Rep"   26-->28
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // "Vlr Com Cood"		      27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // "% Com Cood"			  28-->30
               _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                    // "% Com Nota Coord"        29-->31  
			   _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // "Media % Sistemica Coord" 30-->32 
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // "Vlr Com Ger"		      31-->33
			   _aLinhaNF[34] :=	U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // "% Com Ger"			      32-->34
               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // "% Com Nota Ger"          33-->35
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // "Media % Sistemica Ger"   34-->36
			   _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                     // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                     // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                     // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                     // "Media % Sistemica Ger Nac"   

            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime Coordenador  // 4
			   _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // _aLinhaNF[12] := SD1->D1_TOTAL                                                   // 12  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc) // 13  Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  Desconto do item.	// SD1->D1_DESC			
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // (SD1->D1_TOTAL/_nValTotMerc) // 15  
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                      // _nbasecomis * _nPercItem //  (SD1->D1_TOTAL/_nValTotMerc)                      // 16  
			   _aLinhaNF[25] := _aLinhaNF[16] * (_nComisVend / 100)                             // 23-->25  
			   _aLinhaNF[26] := _nComisVend                                                     // 24-->26 
			   _aLinhaNF[27] := _nPerSisVd                                                      // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := _nMedSisVd                                                      // "Media % Sistemica Rep"   26-->28 
			   _aLinhaNF[29] := _aLinhaNF[16] * (_nComisSuper / 100)                            // "Vlr Com Sup"             27-->29
			   _aLinhaNF[30] := _nComisSuper                                                    // "% Com Sup"	             28-->30
               _aLinhaNF[31] := _nPerSisSp                                                      // "% Com Nota Sup"          29-->31
               _aLinhaNF[32] := _nMedSisSp                                                      // "Media % Sistemica Sup"   30-->32  
			   _aLinhaNF[33] := _aLinhaNF[16] * (_nComisGer / 100)                              // "Vlr Com Ger"             31-->33
			   _aLinhaNF[34] := _nComisGer                                                      // "% Com Ger"	             32-->34
               _aLinhaNF[35] := _nPerSisGe                                                      // "% Com Nota Ger"          33-->35
               _aLinhaNF[36] := _nMedSisGe                                                      // "Media % Sistemica Ger"   34-->36
               _aLinhaNF[37] := _aLinhaNF[16]  * (_nComisGNac / 100)	                         // "Vlr Com Ger Nac"  
			   _aLinhaNF[38] := _nComisGNac                                                      // "% Com Ger Nac"    
               _aLinhaNF[39] := _nPerSisGN                                                       // "% Com Nota Ger Nac",;         
			   _aLinhaNF[40] := _nMedSisGN                                                       // "Media % Sistemica Ger Nac",;  			   

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16  
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 23-->25  
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 24-->26  
			   _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // "% Com Nota Rep",;         25-->27 
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // "Media % Sistemica Rep",;  26-->28 
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                    // "Vlr Com Sup"              27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // "% Com Sup"	               28-->30
               _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // "% Com Nota Sup"           29-->31 
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // "Media % Sistemica Sup"    30-->32 
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // "% Com Ger"	               32-->34
               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // "% Com Nota Ger"           33-->35 
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // "Media % Sistemica Ger"    34-->36 
               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // "Media % Sistemica Ger Nac"   

            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente     // 5 
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      //_aLinhaNF[12] := SD1->D1_TOTAL                                                   // 12  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              //(SD1->D1_TOTAL/_nValTotMerc)   // 13  Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  Desconto do item. // SD1->D1_DESC		
		       _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // (SD1->D1_TOTAL/_nValTotMerc)  // 15 
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem // _nbasecomis * _nPercItem // (SD1->D1_TOTAL/_nValTotMerc)           // 16 
			   _aLinhaNF[25] := _aLinhaNF[16] * (_nComisVend / 100)                             // 23-->25 
			   _aLinhaNF[26] := _nComisVend                                                     // 24-->26 
               _aLinhaNF[27] := _nPerSisVd                                                      // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := _nMedSisVd                                                      // "Media % Sistemica Rep"   26-->28 
			   _aLinhaNF[29] := _aLinhaNF[16] * (_nComisSuper / 100)                            //  "Vlr Com Sup"            27-->29
			   _aLinhaNF[30] := _nComisSuper                                                    // "% Com Sup"	             28-->30
               _aLinhaNF[31] := _nPerSisSp                                                      // "% Com Nota Sup"          29-->31 
               _aLinhaNF[32] := _nMedSisSp                                                      // "Media % Sistemica Sup"   30-->32
			   _aLinhaNF[33] := _aLinhaNF[16] * (_nComisCoord / 100)                            // "Vlr Com Cood"            31-->33 
			   _aLinhaNF[34] := _nComisCoord                                                    // "% Com Cood"	             32-->34
               _aLinhaNF[35] := _nPerSisCo                                                      // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] := _nMedSisCo                                                      // "Media % Sistemica Coord" 34-->36 
               _aLinhaNF[37] := _aLinhaNF[16]  * (_nComisGNac / 100)	                         // "Vlr Com Ger Nac"  
			   _aLinhaNF[38] := _nComisGNac                                                      // "% Com Ger Nac"    
               _aLinhaNF[39] := _nPerSisGN                                                       // "% Com Nota Ger Nac",;         
			   _aLinhaNF[40] := _nMedSisGN                                                       // "Media % Sistemica Ger Nac",;  			   

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
		       _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15 
	           _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 15 
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 23-->25 
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 24-->26 
               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // "Media % Sistemica Rep"   26-->28
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                    //  "Vlr Com Sup"            27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // "% Com Sup"	              28-->30
               _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // "% Com Nota Sup",;        29-->31
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // "Media % Sistemica Sup"   30-->32
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // "Vlr Com Cood"            31-->33 
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // "% Com Cood"	          32-->34
               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // "Media % Sistemica Coord" 34-->36 
               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // "Media % Sistemica Ger Nac"   
           
		   ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente nacional 
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               
		       _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem  
			   _aLinhaNF[25] := _aLinhaNF[16] * (_nComisVend / 100)                             // 23-->25 
			   _aLinhaNF[26] := _nComisVend                                                     // 24-->26 
               _aLinhaNF[27] := _nPerSisVd                                                      // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := _nMedSisVd                                                      // "Media % Sistemica Rep"   26-->28 
			   _aLinhaNF[29] := _aLinhaNF[16] * (_nComisSuper / 100)                            //  "Vlr Com Sup"            27-->29
			   _aLinhaNF[30] := _nComisSuper                                                    // "% Com Sup"	             28-->30
               _aLinhaNF[31] := _nPerSisSp                                                      // "% Com Nota Sup"          29-->31 
               _aLinhaNF[32] := _nMedSisSp                                                      // "Media % Sistemica Sup"   30-->32
			   _aLinhaNF[33] := _aLinhaNF[16] * (_nComisCoord / 100)                            // "Vlr Com Cood"            31-->33 
			   _aLinhaNF[34] := _nComisCoord                                                    // "% Com Cood"	             32-->34
               _aLinhaNF[35] := _nPerSisCo                                                      // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] := _nMedSisCo                                                      // "Media % Sistemica Coord" 34-->36 
               _aLinhaNF[37] := _aLinhaNF[16] * (_nComisGer / 100)                              // "Vlr Com Ger"             
			   _aLinhaNF[38] := _nComisGer                                                      // "% Com Ger"	             
               _aLinhaNF[39] := _nPerSisGe                                                      // "% Com Nota Ger"          
               _aLinhaNF[40] := _nMedSisGe                                                      // "Media % Sistemica Ger"   

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
		       _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15 
	           _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 15 
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 23-->25 
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 24-->26 
               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // "Media % Sistemica Rep"   26-->28
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                    //  "Vlr Com Sup"            27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // "% Com Sup"	              28-->30
               _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // "% Com Nota Sup",;        29-->31
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // "Media % Sistemica Sup"   30-->32
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // "Vlr Com Cood"            31-->33 
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // "% Com Cood"	          32-->34
               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // "Media % Sistemica Coord" 34-->36 
               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // "Vlr Com Ger"              
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // "% Com Ger"	               
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // "% Com Nota Ger"            
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // "Media % Sistemica Ger"     
 
            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07  .And. ! "N" $ MV_PAR07  // imprime apenas gerente  // 6
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // _aLinhaNF[12] := SD1->D1_TOTAL                                                   // 12  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc)      // 13  Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  Desconto do item.  //SD1->D1_DESC 							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               //(SD1->D1_TOTAL/_nValTotMerc)             // 15  
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                      // _nbasecomis * _nPercItem // (SD1->D1_TOTAL/_nValTotMerc)                      // 16  
			   _aLinhaNF[19] := _aLinhaNF[16] * (_nComisGer / 100)                              // 19  
			   _aLinhaNF[20] := _nComisGer                                                      // 20  
			   _aLinhaNF[21] := _nPerSisGe                                                      // "% Com Nota Ger",;          // 21 A 
               _aLinhaNF[22] := _nMedSisGe                                                      // "Media % Sistemica Ger",;   // 22 A
	
			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16  
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                   // 19  
			   _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                   // 20  
               _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                    // "% Com Nota Ger",;          // 21 A 
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                    // "Media % Sistemica Ger",;   // 22 A
 
            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador // 7 
           	   _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem  // _aLinhaNF[12] := SD1->D1_TOTAL                                                   // 12  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc)     // 13  Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  Desconto do item.	// SD1->D1_DESC				
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // (SD1->D1_TOTAL/_nValTotMerc)     // 15  
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                      // _nbasecomis * _nPercItem         // (SD1->D1_TOTAL/_nValTotMerc)                      // 16  
			   _aLinhaNF[19] := _aLinhaNF[16] * (_nComisCoord / 100)                            // 19  
               _aLinhaNF[20] := _nComisCoord                                                    // 20  
	           _aLinhaNF[21] := _nPerSisCo                                                      // "% Com Nota Coord",;        // 21 A
               _aLinhaNF[22] := _nMedSisCo                                                      // "Media % Sistemica Coord",; // 22 A 

	           //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16  
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                    // 19  
               _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                    // 20  
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                    // "% Com Nota Coord",;        // 21 A
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                    // "Media % Sistemica Coord",; // 22 A 
               
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas supervisor  // 8
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // _aLinhaNF[12] := SD1->D1_TOTAL                                                   // 12  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc)    // 13  Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  Desconto do item.	// SD1->D1_DESC						
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // (SD1->D1_TOTAL/_nValTotMerc)             // 15  
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                      // _nbasecomis * _nPercItem // (SD1->D1_TOTAL/_nValTotMerc)                      // 16  
			   _aLinhaNF[19] := _aLinhaNF[16] * (_nComisSuper / 100)                            // 19  
			   _aLinhaNF[20] := _nComisSuper                                                    // 20  
               _aLinhaNF[21] := _nPerSisSp                                                      // "% Com Nota Sup",;          // 21 A
               _aLinhaNF[22] := _nMedSisSp                                                      // "Media % Sistemica Sup",;   // 22 A

               //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13  Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16  
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                    // 19  
			   _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                    // 20  
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                    // "% Com Nota Sup",;          // 21 A
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                    // "Media % Sistemica Sup",;   // 22 A

            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor  // 9 
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     // _aLinhaNF[12] := SD1->D1_TOTAL                                                   // 12 Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             // (SD1->D1_TOTAL/_nValTotMerc)            // 13 Compensação
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              // 14  Desconto do item.		//SD1->D1_DESC					
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              // (SD1->D1_TOTAL/_nValTotMerc)             // 15  
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                     // _nbasecomis * _nPercItem // (SD1->D1_TOTAL/_nValTotMerc)                      // 16  
			   _aLinhaNF[19] := _aLinhaNF[16] * (_nComisVend / 100)                            // 19  
		       _aLinhaNF[20] := _nComisVend                                                    // 20  
               _aLinhaNF[21] := _nPerSisVd                                                     // "% Com Nota Rep",;          // 21 A
               _aLinhaNF[22] := _nMedSisVd                                                     // "Media % Sistemica Rep",;   // 22 A

               //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12 Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13 Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16  
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                    // 19  
		       _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                    // 20  
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                    // "% Com Nota Rep",;          // 21 A
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                    // "Media % Sistemica Rep",;   // 22 A

            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas Gerente Nacional  
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              
			   _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                     
               _aLinhaNF[19] := _aLinhaNF[16]  * (_nComisGNac / 100)	                         // "Vlr Com Ger Nac"  
			   _aLinhaNF[20] := _nComisGNac                                                      // "% Com Ger Nac"    
               _aLinhaNF[21] := _nPerSisGN                                                       // "% Com Nota Ger Nac",;         
			   _aLinhaNF[22] := _nMedSisGN                                                       // "Media % Sistemica Ger Nac",;  			   
 
			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12 Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13 Compensação
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15  
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16  
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                    // 19  
		       _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                    // 20  
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                    // "% Com Nota Rep",;          // 21 A
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                    // "Media % Sistemica Rep",;   // 22 A
            EndIf

            _cDescPrd := Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC")     // Desc. Prod.
            _cBIMIX   := Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_I_BIMIX")  // Mix BI
            
			aAdd(_aLinhaNF, _cBIMIX        )    // Mix BI
            aAdd(_aLinhaNF, SD1->D1_ITEM   )    // "Item"           
            aAdd(_aLinhaNF, SD1->D1_COD    )    // "Produto"           
            aAdd(_aLinhaNF, _cDescPrd      )    // "Descrição"        
			aAdd(_aLinhaNF, U_ROMS025I(SD1->D1_PICM,"@E 999,999,999.999"))          // "Aliq.%"           
            aAdd(_aLinhaNF, U_ROMS025I(SD1->D1_QUANT,"@E 999,999,999.999"))         // "Qtde"             
			aAdd(_aLinhaNF, SD1->D1_UM     )    // "U.M."               
			aAdd(_aLinhaNF, U_ROMS025I(SD1->D1_QTSEGUM,"@E 999,999,999.999"))       // "Qtde 2a U.M."  
            aAdd(_aLinhaNF, SD1->D1_SEGUM  )    // "2a U.M."         
            aAdd(_aLinhaNF, U_ROMS025I(SD1->D1_VUNIT,"@E 999,999,999.999"))         // "Vlr.Uni."        
            aAdd(_aLinhaNF, U_ROMS025I(SD1->D1_TOTAL,"@E 999,999,999.999"))         // "Valor Total"     

            aAdd(_aLinhaNF, SD1->D1_NFORI  )    // "NF.Origem"       
            aAdd(_aLinhaNF, SD1->D1_SERIORI)    // "Serie Origem"  
            
            For i := 1 to Len(_aDadosRAD)
               aAdd(_aLinhaNF,_aDadosRAD[i])
            Next

            aAdd(_aRet, AClone(_aLinhaNF))
                        
            SD1->(DBSkip())
         EndDo
      Else
         _aLinhaNF := {}
         For _nI := 1 To Len(_aDadosR)
             aAdd(_aLinhaNF, _aDadosR[_nI])
         Next
         
         //SE1->(DBSetOrder(31)) // 31 - V - E1_FILIAL+E1_NUM+E1_SERIE+E1_CLIENTE+E1_LOJA    
         SE1->(DBSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO    
         
         If SE1->(DBSeek(U_ItKey(_cFilialNF,"E1_FILIAL")+U_ItKey(_cCodCli,"E1_CLIENTE")+U_ItKey(_cLojaCli,"E1_LOJA")+U_ItKey("DCT","E1_PREFIXO")+U_ItKey(_cNRNF,"E1_NUM")  ))
            While ! SE1->(Eof()) .And. SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM) == U_ItKey(_cFilialNF,"E1_FILIAL")+U_ItKey(_cCodCli,"E1_CLIENTE")+U_ItKey(_cLojaCli,"E1_LOJA")+U_ItKey("DCT","E1_PREFIXO")+U_ItKey(_cNRNF,"E1_NUM")
               If AllTrim(SE1->E1_TIPO) == "NCC" .And. AllTrim(SE1->E1_PREFIXO) == "DCT"
                  _aLinhaNF[2] := "DCT"
                  Exit
               EndIf
               
               SE1->(DBSkip())
            EndDo
         EndIf

         If ValType(_aLinhaNF[12]) == "N"
            _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12   Valor total do item.	
	     EndIf
		 If ValType(_aLinhaNF[13]) == "N"
			_aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13   Compensação  
		 EndIf	
		 If ValType(_aLinhaNF[14]) == "N"
			_aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14   Desconto do item.							
		 EndIf
		 If ValType(_aLinhaNF[15]) == "N"
			_aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15   
		 EndIf
		 If ValType(_aLinhaNF[16]) == "N"
			_aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16   
		 EndIf	
		 If Len(_aLinhaNF) >= 25 .And. ValType(_aLinhaNF[25]) == "N"
			_aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 25   
	     EndIf		
		 If Len(_aLinhaNF) >= 26 .And. ValType(_aLinhaNF[26]) == "N"
			_aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 26   
	     EndIf		
		 If Len(_aLinhaNF) >= 27 .And. ValType(_aLinhaNF[27]) == "N"
			_aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // 27  
		 EndIf	
		 If Len(_aLinhaNF) >= 28 .And. ValType(_aLinhaNF[28]) == "N"
			_aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // 28   
		 EndIf	
		 If Len(_aLinhaNF) >= 30 .And. ValType(_aLinhaNF[30]) == "N"
			_aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // 30   
		 EndIf	
		 If Len(_aLinhaNF) >= 31 .And. ValType(_aLinhaNF[31]) == "N"
			_aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // 31   
		 EndIf	
		 If Len(_aLinhaNF) >= 32 .And. ValType(_aLinhaNF[32]) == "N"
			_aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // 32   
		 EndIf 	
		 If Len(_aLinhaNF) >= 33 .And. ValType(_aLinhaNF[33]) == "N"
			_aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // 33   
		 EndIf 
		 If Len(_aLinhaNF) >= 34 .And. ValType(_aLinhaNF[34]) == "N"
			_aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // 34   
		 EndIf 
		 If Len(_aLinhaNF) >= 35 .And. ValType(_aLinhaNF[35]) == "N"
			_aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // 35   
		 EndIf 
		 If Len(_aLinhaNF) >= 36 .And. ValType(_aLinhaNF[36]) == "N"
			_aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // 36   
		 EndIf 
		 If Len(_aLinhaNF) >= 37 .And. ValType(_aLinhaNF[37]) == "N"
			_aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // 37   
		 EndIf 
		 If Len(_aLinhaNF) >= 38 .And. ValType(_aLinhaNF[38]) == "N"
			_aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // 38   
		 EndIf 
		 If Len(_aLinhaNF) >= 39 .And. ValType(_aLinhaNF[39]) == "N"
			_aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // 39   
		 EndIf
         If Len(_aLinhaNF) >= 40 .And. ValType(_aLinhaNF[40]) == "N"
			_aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // 40   
		 EndIf

         If Len(_aLinhaNF) >= 41 .And. ValType(_aLinhaNF[41]) == "N"
			_aLinhaNF[41] := U_ROMS025I(_aLinhaNF[41],"@E 999,999,999.999")                    // 41   
		 EndIf

		 If Len(_aLinhaNF) >= 42 .And. ValType(_aLinhaNF[42]) == "N"
			_aLinhaNF[42] := U_ROMS025I(_aLinhaNF[42],"@E 999,999,999.999")                    // 42   
		 EndIf

		 If Len(_aLinhaNF) >= 43 .And. ValType(_aLinhaNF[43]) == "N"
			_aLinhaNF[43] := U_ROMS025I(_aLinhaNF[43],"@E 999,999,999.999")                    // 43   
		 EndIf

		 If Len(_aLinhaNF) >= 44 .And. ValType(_aLinhaNF[44]) == "N"
			_aLinhaNF[44] := U_ROMS025I(_aLinhaNF[44],"@E 999,999,999.999")                    // 44   
		 EndIf

		 If Len(_aLinhaNF) >= 45 .And. ValType(_aLinhaNF[45]) == "N"
			_aLinhaNF[45] := U_ROMS025I(_aLinhaNF[45],"@E 999,999,999.999")                    // 45   
		 EndIf

		 If Len(_aLinhaNF) >= 46 .And. ValType(_aLinhaNF[46]) == "N"
			_aLinhaNF[46] := U_ROMS025I(_aLinhaNF[46],"@E 999,999,999.999")                    // 46   
		 EndIf

         For i := 1 to Len(_aDadosRAD)
            aAdd(_aLinhaNF,_aDadosRAD[i])
         Next
		 
       aAdd(_aLinhaNF, "" )    // Mix BI
         aAdd(_aLinhaNF, "" )    // "Item"           
         aAdd(_aLinhaNF, "" )    // "Produto"           
         aAdd(_aLinhaNF, "" )    // "Descrição"        
         aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99"))    // "Aliq.%"           
         aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99"))    // "Qtde"             
         aAdd(_aLinhaNF, "" )    // "U.M."               
         aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99"))    // "Qtde 2a U.M."  
         aAdd(_aLinhaNF, "" )    // "2a U.M."         
         aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99"))    // "Vlr.Uni."        
         aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99"))    // "Valor Total"     
         aAdd(_aLinhaNF, "" )    // "NF.Origem"       
         aAdd(_aLinhaNF, "" )    // "Serie Origem"  


         
         aAdd(_aRet, AClone(_aLinhaNF))
             
      EndIf

      Break
   EndIf   

   //==========================================================================
   //  Nota fiscal de venda.
   //==========================================================================
   If AllTrim(_cTipoDoc) <> "NCC" // Venda
      _nValTotMerc := 1 // Inicializado com um para divisão.
     
      _nRegSF2 := SF2->(Recno())
       
      SF2->(DBSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
      If SF2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
         _nValTotMerc := SF2->F2_VALMERC
      EndIf
      
      SF2->(DBGoTo(_nRegSF2))
       
	  _nTotNF := _nValTotMerc //SF2->F2_VALMERC 

      _nFatorBas := _aDadosR[16] / _nTotNF

      SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
      If SD2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
         While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")
            _aLinhaNF := {}
            For _nI := 1 To Len(_aDadosR)
                aAdd(_aLinhaNF, _aDadosR[_nI])
            Next

            If AllTrim(_cTipoDoc ) == "BON"
               _aLinhaNF[02] := "BON"
            EndIf
            
            //_nComisItem := (SD2->D2_TOTAL * SD2->D2_COMIS1 * _nFatorBas) / 100

			_nPercItem := SD2->D2_TOTAL / _nTotNF 
            
            _nMedSisVd := (SD2->D2_TOTAL * SD2->D2_COMIS1 * _nFatorBas) / 100
			_nMedSisSp := (SD2->D2_TOTAL * SD2->D2_COMIS4 * _nFatorBas) / 100
			_nMedSisCo := (SD2->D2_TOTAL * SD2->D2_COMIS2 * _nFatorBas) / 100
			_nMedSisGe := (SD2->D2_TOTAL * SD2->D2_COMIS3 * _nFatorBas) / 100 
            _nMedSisGN := (SD2->D2_TOTAL * SD2->D2_COMIS5 * _nFatorBas) / 100 
            _nPerSisVd := (_nMedSisVd / SD2->D2_TOTAL / _nFatorBas) * 100
			_nPerSisSp := (_nMedSisSp / SD2->D2_TOTAL / _nFatorBas) * 100
			_nPerSisCo := (_nMedSisCo / SD2->D2_TOTAL / _nFatorBas) * 100
			_nPerSisGe := (_nMedSisGe / SD2->D2_TOTAL / _nFatorBas) * 100
            _nPerSisGN := (_nMedSisGN / SD2->D2_TOTAL / _nFatorBas) * 100

            If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados // 1
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                    // 12   SD2->D2_TOTAL  =  Valor total do item.	
			      _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem            // 13   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			      _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem             // 14   SD2->D2_DESC    = Desconto do item.							
			      _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem             // 15   ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
               If AllTrim(_aLinhaNF[02]) == "BON"
			         _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                 // * -1 //_nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão. O Valor é negativo.  
			      Else
			         _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                 // _nbasecomis * _nPercItem                                     // 16   ( _nbasecomis * (SD2->D2_TOTAL/(_cAlias)->VLRTITULO))
			      EndIf

			   _aLinhaNF[27] := _aLinhaNF[16] * (SD2->D2_COMIS1 / 100)        // 25-->27   Percentual comissão 1 - Vendedor
			   _aLinhaNF[28] := SD2->D2_COMIS1                                // 26-->28   comissão 1 - Vendedor 

               _aLinhaNF[29] := _nPerSisVd                                    // "% Com Nota Rep"          27-->29
 			   _aLinhaNF[30] := _nMedSisVd                                    // "Media % Sistemica Rep"   28-->30

			   _aLinhaNF[31] := _aLinhaNF[16] * (SD2->D2_COMIS4 / 100)        // "Vlr Com Sup"             29-->31 
			   _aLinhaNF[32] := SD2->D2_COMIS4	                              // "% Com Sup"	           30-->32 
			   
			   _aLinhaNF[33] := _nPerSisSp                                    // "% Com Nota Sup"          31-->33
			   _aLinhaNF[34] := _nMedSisSp                                    // "Media % Sistemica Sup"   32-->34 

			   _aLinhaNF[35] := _aLinhaNF[16] * (SD2->D2_COMIS2 / 100)		  // "Vlr Com Cood"            33-->35
			   _aLinhaNF[36] := SD2->D2_COMIS2	                              // "% Com Cood"	           34-->36 

               _aLinhaNF[37] := _nPerSisCo                                    // "% Com Nota Coord         35-->37
			   _aLinhaNF[38] := _nMedSisCo                                    // "Media % Sistemica Coord  36-->38  

			   _aLinhaNF[39] := _aLinhaNF[16]  * (SD2->D2_COMIS3 / 100)	      // "Vlr Com Ger"             37-->39
			   _aLinhaNF[40] := SD2->D2_COMIS3                                // "% Com Ger"	           38-->40

			   _aLinhaNF[41] := _nPerSisGe                                    // "% Com Nota Ger"          39-->41
			   _aLinhaNF[42] := _nMedSisGe                                    // "Media % Sistemica Ger"   40-->42

               _aLinhaNF[43] := _aLinhaNF[16]  * (SD2->D2_COMIS5 / 100)	      // "Vlr Com Ger Nac"
			   _aLinhaNF[44] := SD2->D2_COMIS5                                // "% Com Ger Nac"

			   _aLinhaNF[45] := _nPerSisGN                                    // "% Com Nota Ger Nac"
			   _aLinhaNF[46] := _nMedSisGN                                    // "Media % Sistemica Ger Nac"

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999") // 12   SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999") // 13   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999") // 14   SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999") // 15   ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
               _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999") // 16   ( _nbasecomis * (SD2->D2_TOTAL/(_cAlias)->VLRTITULO))
			   _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999") // 25-->27  Percentual comissão 1 - Vendedor
			   _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999") // 26-->28  comissão 1 - Vendedor 
               _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999") // "% Com Nota Rep"           27-->29 
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999") // "Media % Sistemica Rep"    28-->30
			   _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999") // "Vlr Com Sup"              29-->31 
			   _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999") // "% Com Sup"	            30-->32 
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999") // "% Com Nota Sup"           31-->33 
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999") // "Media % Sistemica Sup"    32-->34
			   _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999") // "Vlr Com Cood"             33-->35
			   _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999") // "% Com Cood"	            34-->36 
               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999") // "% Com Nota Coord"         35-->37
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999") // "Media % Sistemica Coord   36-->38
			   _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999") // "Vlr Com Ger"              37-->39 
			   _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999") // "% Com Ger"	            38-->40 
			   _aLinhaNF[41] := U_ROMS025I(_aLinhaNF[41],"@E 999,999,999.999") // "% Com Nota Ger"           39-->41 
			   _aLinhaNF[42] := U_ROMS025I(_aLinhaNF[42],"@E 999,999,999.999") // "Media % Sistemica Ger"    40-->42 
               _aLinhaNF[43] := U_ROMS025I(_aLinhaNF[43],"@E 999,999,999.999") // "Vlr Com Ger Nac"             
			   _aLinhaNF[44] := U_ROMS025I(_aLinhaNF[44],"@E 999,999,999.999") // "% Com Ger Nac"		       
               _aLinhaNF[45] := U_ROMS025I(_aLinhaNF[45],"@E 999,999,999.999") // "% Com Nota Ger Nac"          
               _aLinhaNF[46] := U_ROMS025I(_aLinhaNF[46],"@E 999,999,999.999") // "Media % Sistemica Ger Nac"   

            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor     // 2
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem           // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/(_cAlias)->VLRTITULO)) 
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem            // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem            // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                //* -1 // _nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão. O Valor é negativo.  
			   Else
			      _aLinhaNF[16]	:= _aLinhaNF[16] * _nPercItem                // _nbasecomis * _nPercItem                                     // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf

			   _aLinhaNF[25] := _aLinhaNF[16] * (SD2->D2_COMIS4 / 100)       // 23-->25  Percentual comissão Supervidor
			   _aLinhaNF[26] := SD2->D2_COMIS4                               // 24-->26  comissão  - Supervidor

               _aLinhaNF[27] := _nPerSisSp                                   // "% Com Nota Sup"           25-->27 
               _aLinhaNF[28] := _nMedSisSp                                   // "Media % Sistemica Sup"    26-->28 

			   _aLinhaNF[29] := _aLinhaNF[16] * (SD2->D2_COMIS2 / 100)       // "Vlr Com Cood"             27-->29
			   _aLinhaNF[30] := SD2->D2_COMIS2                               // "% Com Cood"               28-->30

			   _aLinhaNF[31] := _nPerSisCo                                   // "% Com Nota Coord"         29-->31
               _aLinhaNF[32] := _nMedSisCo                                   // "Media % Sistemica Coord"  30-->32

			   _aLinhaNF[33] := _aLinhaNF[16] * (SD2->D2_COMIS3 / 100)       // "Vlr Com Ger"              31-->33
			   _aLinhaNF[34] := SD2->D2_COMIS3                               // "% Com Ger"	               32-->34

			   _aLinhaNF[35] := _nPerSisGe                                   // "% Com Nota Ger"           33-->35 
               _aLinhaNF[36] := _nMedSisGe                                   // "Media % Sistemica Ger"    34-->36

               _aLinhaNF[37] := _aLinhaNF[16]  * (SD2->D2_COMIS5 / 100)	      // "Vlr Com Ger Nac"
			   _aLinhaNF[38] := SD2->D2_COMIS5                                // "% Com Ger Nac"

			   _aLinhaNF[39] := _nPerSisGN                                    // "% Com Nota Ger Nac"
			   _aLinhaNF[40] := _nMedSisGN                                    // "Media % Sistemica Ger Nac"

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")	   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")	   // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/(_cAlias)->VLRTITULO)) 
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")	   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")	   // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")	   // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")	   // 23-->25  Percentual comissão Supervidor
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")	   // 24-->26  Comissão Supervidor
               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")      // "% Com Nota Sup"           25-->27 
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")      // "Media % Sistemica Sup"    26-->28  
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")      // "Vlr Com Cood"             27-->29 
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")      // "% Com Cood"               28-->30 
			   _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")      // "% Com Nota Coord"         29-->31 
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")      // "Media % Sistemica Coord"  30-->32
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")      // "Vlr Com Ger"              31-->33
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")      // "% Com Ger"	             32-->34
			   _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")      // "% Com Nota Ger"           33-->35
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")      // "Media % Sistemica Ger"    34-->36 
               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")      // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")      // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")      // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")      // "Media % Sistemica Ger Nac"  

            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor  // 3
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // 13   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14 D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // 15 ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc) 
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem //* -1 // _nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão.  
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem      // _nbasecomis * _nPercItem                  	                // 16 ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf

			   _aLinhaNF[25] := _aLinhaNF[16] * (SD2->D2_COMIS1 / 100) 	  // 23-->25 Percentual comissão Vendedor
			   _aLinhaNF[26] := SD2->D2_COMIS1	                          // 24-->26 comissão Vendedor
               _aLinhaNF[27] := _nPerSisVd                                // "% Com Nota Rep"            25-->27  
               _aLinhaNF[28] := _nMedSisVd                                // "Media % Sistemica Rep"     26-->28 

			   _aLinhaNF[29] := _aLinhaNF[16] * (SD2->D2_COMIS2 / 100)	  // "Vlr Com Cood"              27-->29 
			   _aLinhaNF[30] := SD2->D2_COMIS2	                          // "% Com Cood"	             28-->30 
               _aLinhaNF[31] := _nPerSisCo                                // "% Com Nota Coord"          29-->31 
               _aLinhaNF[32] := _nMedSisCo                                // "Media % Sistemica Coord"   30-->32 

			   _aLinhaNF[33] := _aLinhaNF[16] * (SD2->D2_COMIS3 / 100)    // "Vlr Com Ger"                31-->33
			   _aLinhaNF[34] :=	SD2->D2_COMIS3                            // "% Com Ger"	              32-->34
               _aLinhaNF[35] := _nMedSisGe                                // "% Com Nota Ger"             33-->35
               _aLinhaNF[36] := _nPerSisGe                                // "Media % Sistemica Ger"      34-->36

               _aLinhaNF[37] := _aLinhaNF[16]  * (SD2->D2_COMIS5 / 100)	      // "Vlr Com Ger Nac"
			   _aLinhaNF[38] := SD2->D2_COMIS5                                // "% Com Ger Nac"

			   _aLinhaNF[39] := _nPerSisGN                                    // "% Com Nota Ger Nac"
			   _aLinhaNF[40] := _nMedSisGN                                    // "Media % Sistemica Ger Nac" 

               //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
         	   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")     // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")     // 13   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999") 	 // 14 D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999") 	 // 15 ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc) 
		       _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999") 	 // 16 ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999") 	 // 23-->25 Percentual comissão Vendedor
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")    // 24-->26 comissão Vendedor
			   
			   _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")    // "% Com Nota Rep"           25-->27  
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")    // "Media % Sistemica Rep"    26-->28 
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")    // "Vlr Com Cood"             27-->29 
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999") 	 // "% Com Cood"	           28-->30 
               _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")    // "% Com Nota Coord"         29-->31
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")    // "Media % Sistemica Coord"  30-->32
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")    // "Vlr Com Ger"              31-->33
			   _aLinhaNF[34] :=	U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")    // "% Com Ger"	               32-->34
               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")    // "% Com Nota Ger"           33-->35
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")    // "Media % Sistemica Ger"    34-->36
               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")    // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")    // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")    // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")    // "Media % Sistemica Ger Nac"  

            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime Coordenador  // 4 
			   _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                  // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem          // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem           // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem           // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc) 
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem //* -1        // _nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão. O valor deve ser negativo. 
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem               // _nbasecomis * _nPercItem                                     // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf

			   _aLinhaNF[25] := _aLinhaNF[16] * _nPercItem                  // 23-->25 Percentual comissão Vendedor
			   _aLinhaNF[26] := SD2->D2_COMIS1                              // 24-->26 Comissão Vendedor
			   _aLinhaNF[27] := _nPerSisVd                                  // "% Com Nota Rep"           25-->27
               _aLinhaNF[28] := _nMedSisVd                                  // "Media % Sistemica Rep"    26-->28 
			   _aLinhaNF[29] := _aLinhaNF[16] * _nPercItem                  // "Vlr Com Sup"              27-->29 
			   _aLinhaNF[30] := SD2->D2_COMIS4                              // "% Com Sup"	              28-->30 
			   _aLinhaNF[31] := _nPerSisSp                                  // "% Com Nota Sup",;         29-->31
               _aLinhaNF[32] := _nMedSisSp                                  // "Media % Sistemica Sup"    30-->32
			   _aLinhaNF[33] := _aLinhaNF[16] * _nPercItem                  // "Vlr Com Ger"              31-->33
			   _aLinhaNF[34] := SD2->D2_COMIS3                              // "% Com Ger"	              32-->34
			   _aLinhaNF[35] := _nPerSisGe                                  // "% Com Nota Ger",;         33-->35
               _aLinhaNF[36] := _nMedSisGe                                  // "Media % Sistemica Ger",;  34-->36
               _aLinhaNF[37] := _aLinhaNF[16]  * (SD2->D2_COMIS5 / 100)	    // "Vlr Com Ger Nac"
			   _aLinhaNF[38] := SD2->D2_COMIS5                              // "% Com Ger Nac"

			   _aLinhaNF[39] := _nPerSisGN                                  // "% Com Nota Ger Nac"
			   _aLinhaNF[40] := _nMedSisGN                                  // "Media % Sistemica Ger Nac" 

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc) 
               _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)

			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 23-->25  Percentual comissão Vendedor
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 24-->26  Comissão Vendedor

			   _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // "% Com Nota Rep"           25-->27
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // "Media % Sistemica Rep"    26-->28
			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                    // "Vlr Com Sup"	           27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // "% Com Sup"	               28-->30
			   _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // "% Com Nota Sup",;         29-->31
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // "Media % Sistemica Sup"    30-->32 
			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // "Vlr Com Ger"              31-->33
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // "% Com Ger"	               32-->34
			   _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // "% Com Nota Ger"           33-->35
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // "Media % Sistemica Ger"    34-->36 

               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")    // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")    // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")    // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")    // "Media % Sistemica Ger Nac"  

            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07  .And. "N" $ MV_PAR07 // Não imprime gerente  // 5 
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // 15 ((_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)

			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem //* -1 // _nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão. O valor deve ser negativo.  
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem // _nbasecomis * _nPercItem                                     // 16 ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf

			   _aLinhaNF[25] := _aLinhaNF[16]  * (SD2->D2_COMIS1 / 100)                         // 23-->25 Percentual comissão Vendedor
			   _aLinhaNF[26] := SD2->D2_COMIS1                                                  // 24-->26 Comissão Vendedor

               _aLinhaNF[27] :=  _nPerSisVd                                                     // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] :=  _nMedSisVd                                                     // "Media % Sistemica Rep"   26-->28

			   _aLinhaNF[29] := _aLinhaNF[16] * (SD2->D2_COMIS4 / 100)                          // "Vlr Com Sup"             27-->29
			   _aLinhaNF[30] := SD2->D2_COMIS4                                                  // "% Com Sup"	             28-->30
            
			   _aLinhaNF[31] := _nPerSisSp                                                      // "% Com Nota Sup"          29-->31
               _aLinhaNF[32] := _nMedSisSp                                                      // "Media % Sistemica Sup"   30-->32

			   _aLinhaNF[33] := _aLinhaNF[16] * (SD2->D2_COMIS2 / 100)                          // "Vlr Com Cood"            31-->33
			   _aLinhaNF[34] := SD2->D2_COMIS2                                                  // "% Com Cood"	             32-->34

               _aLinhaNF[35] :=  _nPerSisCo                                                     // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] :=  _nMedSisCo                                                     // "Media % Sistemica Coord" 34-->36 

               _aLinhaNF[37] := _aLinhaNF[16]  * (SD2->D2_COMIS5 / 100)	                        // "Vlr Com Ger Nac"
			   _aLinhaNF[38] := SD2->D2_COMIS5                                                  // "% Com Ger Nac"

			   _aLinhaNF[39] := _nPerSisGN                                                      // "% Com Nota Ger Nac"
			   _aLinhaNF[40] := _nMedSisGN                                                      // "Media % Sistemica Ger Nac" 

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15 ((_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
		       _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16 ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)

			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                   // 23-->25 Percentual comissãoVendedor
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                   // 24-->26 comissão Vendedor

               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                   // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                   // "Media % Sistemica Rep"   26-->28

			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                   // "Vlr Com Sup"             27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                   // "% Com Sup"	             28-->30
            
			   _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                   // "% Com Nota Sup"          29-->31
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                   // "Media % Sistemica Sup"   30-->32

			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                   // "Vlr Com Cood"            31-->33
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                   // "% Com Cood"	             32-->34

               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                   // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                   // "Media % Sistemica Coord" 34-->36 

               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                   // "Vlr Com Ger Nac"             
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                   // "% Com Ger Nac"		       
               _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                   // "% Com Nota Ger Nac"          
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                   // "Media % Sistemica Ger Nac"  

            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07  .And. "N" $ MV_PAR07 // Não imprime gerente nacional
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                      // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                              // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                               // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                               // 15 ((_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)

			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem //* -1 // _nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão. O valor deve ser negativo.  
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem // _nbasecomis * _nPercItem                                     // 16 ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf

			   _aLinhaNF[25] := _aLinhaNF[16]  * (SD2->D2_COMIS1 / 100)                         // 23-->25 Percentual comissão Vendedor
			   _aLinhaNF[26] := SD2->D2_COMIS1                                                  // 24-->26 Comissão 1 Vendedor

               _aLinhaNF[27] :=  _nPerSisVd                                                     // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] :=  _nMedSisVd                                                     // "Media % Sistemica Rep"   26-->28

			   _aLinhaNF[29] := _aLinhaNF[16] * (SD2->D2_COMIS4 / 100)                          // "Vlr Com Sup"             27-->29
			   _aLinhaNF[30] := SD2->D2_COMIS4                                                  // "% Com Sup"	             28-->30 
            
			   _aLinhaNF[31] := _nPerSisSp                                                      // "% Com Nota Sup"          29-->31
               _aLinhaNF[32] := _nMedSisSp                                                      // "Media % Sistemica Sup"   30-->32

			   _aLinhaNF[33] := _aLinhaNF[16] * (SD2->D2_COMIS2 / 100)                          // "Vlr Com Cood"            31-->33
			   _aLinhaNF[34] := SD2->D2_COMIS2                                                  // "% Com Cood"	             32-->34

               _aLinhaNF[35] := _nPerSisCo                                                     // "% Com Nota Coord"        33-->35
               _aLinhaNF[36] := _nMedSisCo                                                     // "Media % Sistemica Coord" 34-->36 

               _aLinhaNF[37] := _aLinhaNF[16] * _nPercItem                                      // "Vlr Com Ger"   
			   _aLinhaNF[38] := SD2->D2_COMIS3                                                  // "% Com Ger"	   
			   _aLinhaNF[39] := _nPerSisGe                                                      // "% Com Nota Ger"
               _aLinhaNF[40] := _nMedSisGe                                                      // "Media % Sistemica Ger"

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15 ((_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
		       _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16 ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)

			   _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                   // 23-->25  Percentual ComissãoVendedor
			   _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                   // 24-->26  Comissão Vendedor

               _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                   // "% Com Nota Rep"          25-->27
               _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                   // "Media % Sistemica Rep"   26-->28

			   _aLinhaNF[29] := U_ROMS025I(_aLinhaNF[29],"@E 999,999,999.999")                   // "Vlr Com Sup"             27-->29
			   _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                   // "% Com Sup"	             28-->30
            
			   _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                   // "% Com Nota Sup"          29-->31
               _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                   // "Media % Sistemica Sup"   30-->32

			   _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                   // "Vlr Com Cood"            31-->33
			   _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                   // "% Com Cood"	             32-->34

               _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                   // "% Com Nota Coord"        33-->35 
               _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                   // "Media % Sistemica Coord" 34-->36 

               _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // "Vlr Com Ger"              
			   _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // "% Com Ger"	              
			   _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // "% Com Nota Ger"           
               _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // "Media % Sistemica Ger"     

           ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas gerente nacional
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                  //* -1 // _nbasecomis * _nPercItem * -1  // 16   Bonificação não gera comissão. O valor dever ser negativo.  
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                  // _nbasecomis * _nPercItem   // 16  ( _nbasecomis * (D2_TOTAL/_nValTotMerc) 
			   EndIf

               _aLinhaNF[19] := _aLinhaNF[16]  * (SD2->D2_COMIS5 / 100)	                        // "Vlr Com Ger Nac"
			   _aLinhaNF[20] := SD2->D2_COMIS5                                                  // "% Com Ger Nac"

			   _aLinhaNF[21] := _nPerSisGN                                                      // "% Com Nota Ger Nac"
			   _aLinhaNF[22] := _nMedSisGN                                                      // "Media % Sistemica Ger Nac"  
   

               //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
	           _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16  ( _nbasecomis * (D2_TOTAL/_nValTotMerc) 
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                   // 19  Percentual comissão Gerente nacional
			   _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                   // 20  Comissão Gerente Nacional    
			   
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                   // "% Com Nota Ger Nac"
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                   // "Media % Sistemica Ger Nac"

            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas gerente  // 6 
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                  //* -1 // _nbasecomis * _nPercItem * -1  // 16   Bonificação não gera comissão. O valor dever ser negativo.  
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                  // _nbasecomis * _nPercItem   // 16  ( _nbasecomis * (D2_TOTAL/_nValTotMerc) 
			   EndIf

			   _aLinhaNF[19] := _aLinhaNF[16] * (SD2->D2_COMIS3 / 100)                         // 19  * SD2->D2_COMIS3  - Percentual comissão 3 - Gerente
			   _aLinhaNF[20] := SD2->D2_COMIS3                                                 // 20  = SD2->D2_COMIS3  - Percentual comissão 3 - Gerente

			   _aLinhaNF[21] := _nPerSisGe                                                     // "% Com Nota Ger",;          // 21 A 
               _aLinhaNF[22] := _nMedSisGe                                                     // "Media % Sistemica Ger",;   // 22 A

               //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
	           _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16  ( _nbasecomis * (D2_TOTAL/_nValTotMerc) 
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                   // 19  * SD2->D2_COMIS3  - Percentual comissão 3 - Gerente
			   _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                   // 20  = SD2->D2_COMIS3  - Percentual comissão 3 - Gerente    
			   
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                   // "% Com Nota Ger",;          // 21 A 
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                   // "Media % Sistemica Ger",;   // 22 A

            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador // 7 
           	   _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                   //* -1 // _nbasecomis * _nPercItem * -1                               // 16   Bonificação não gera comissão. O valor deve ser negativo. 
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                   // _nbasecomis * _nPercItem                                    // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf
			   
			   _aLinhaNF[19] := _aLinhaNF[16] * (SD2->D2_COMIS2 / 100)                         // 19  * SD2->D2_COMIS2  - Percentual comissão 2 - Coordenador
               _aLinhaNF[20] := SD2->D2_COMIS2                                                 // 20  = SD2->D2_COMIS2  - Percentual comissão 2 - Coordenador

			   _aLinhaNF[21] := _nPerSisCo                                                     // "% Com Nota Coord",;        // 21 A
               _aLinhaNF[22] := _nMedSisCo                                                     // "Media % Sistemica Coord",; // 22 A 

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
		       _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                   // 19  * SD2->D2_COMIS2  - Percentual comissão 2 - Coordenador
               _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                   // 20  = SD2->D2_COMIS2  - Percentual comissão 2 - Coordenador

			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                   // "% Com Nota Coord",;        // 21 A
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                   // "Media % Sistemica Coord",; // 22 A 

            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas supervisor  // 8
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             // 13  ( (_cAlias)->COMPENSACA * (D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              // 15  ( (_cAlias)->BAIXASANT * (D2_TOTAL/_nValTotMerc)
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                  //* -1  // _nbasecomis * _nPercItem * -1                               // 16   Bonificação não gera comissão. O valor dever ser negativo.  
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                  // _nbasecomis * _nPercItem                                    // 16  ( _nbasecomis * (D2_TOTAL/_nValTotMerc)
			   EndIf
			   
			   _aLinhaNF[19] := _aLinhaNF[16] * (SD2->D2_COMIS4 / 100)                         // 19  * D2_COMIS4  - Percentual comissão 4 - Supervidor
			   _aLinhaNF[20] := SD2->D2_COMIS4                                                 // 20  = D2_COMIS4  - Percentual comissão 4 - Supervidor			   

			   _aLinhaNF[21] := _nPerSisSp                                                     // "% Com Nota Sup",;          // 21 A
               _aLinhaNF[22] := _nMedSisSp                                                     // "Media % Sistemica Sup",;   // 22 A

			   //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
			   _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12  SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13  ( (_cAlias)->COMPENSACA * (D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15  ( (_cAlias)->BAIXASANT * (D2_TOTAL/_nValTotMerc)
               _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16  ( _nbasecomis * (D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                   // 19  * D2_COMIS4  - Percentual comissão 4 - Supervidor
			   _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                   // 20  = D2_COMIS4  - Percentual comissão 4 - Supervidor
													
               _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                   // "% Com Nota Sup",;          // 21 A
			   _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                   // "Media % Sistemica Sup",;   // 22 A

            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor  // 9
               _aLinhaNF[12] := _aLinhaNF[12] * _nPercItem                                     // 12   SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := (_cAlias)->COMPENSACA * _nPercItem                             // 13   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := (_cAlias)->DESCONTO  * _nPercItem                              // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := (_cAlias)->BAIXASANT * _nPercItem                              // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
			   
			   If AllTrim(_aLinhaNF[02]) == "BON"
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                   //* -1  // _nbasecomis * _nPercItem * -1  // 16   Bonificação não gera comissão. O valor deve ser negativo. 
			   Else
			      _aLinhaNF[16] := _aLinhaNF[16] * _nPercItem                                   // _nbasecomis * _nPercItem               // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   EndIf
			   
			   _aLinhaNF[19] := _aLinhaNF[16] * (SD2->D2_COMIS1 / 100)                         // 19  * SD2->D2_COMIS1  - Percentual comissão 1 - Vendedor 
			   _aLinhaNF[20] := SD2->D2_COMIS1                                                 // 20  = SD2->D2_COMIS1  - Percentual comissão 1 - Vendedor

               _aLinhaNF[21] :=  _nPerSisVd                                                    // "% Com Nota Rep",;          // 21 A
               _aLinhaNF[22] :=  _nMedSisVd                                                    // "Media % Sistemica Rep",;   // 22 A

               //==========================================================
			   // Formatando os campos de valores
			   //==========================================================
               _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                   // 12   SD2->D2_TOTAL  =  Valor total do item.	
			   _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                   // 13   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                   // 14  SD2->D2_DESC    = Desconto do item.							
			   _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                   // 15  ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
		       _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                   // 16  ( _nbasecomis * (SD2->D2_TOTAL/_nValTotMerc)
			   _aLinhaNF[19] := U_ROMS025I(_aLinhaNF[19],"@E 999,999,999.999")                   // 19  * SD2->D2_COMIS1  - Percentual comissão 1 - Vendedor 
			   _aLinhaNF[20] := U_ROMS025I(_aLinhaNF[20],"@E 999,999,999.999")                   // 20  = SD2->D2_COMIS1  - Percentual comissão 1 - Vendedor
               
			   _aLinhaNF[21] := U_ROMS025I(_aLinhaNF[21],"@E 999,999,999.999")                   // "% Com Nota Rep",;          // 21 A
               _aLinhaNF[22] := U_ROMS025I(_aLinhaNF[22],"@E 999,999,999.999")                   // "Media % Sistemica Rep",;   // 22 A
            EndIf

            For i := 1 to Len(_aDadosRAD)
               aAdd(_aLinhaNF,_aDadosRAD[i])
            Next
            
            _cDescPrd := Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC")    // Desc. Prod.
			_cBIMIX   := Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_I_BIMIX") // Mix BI
            
			aAdd(_aLinhaNF, _cBIMIX        )                                      // "Mix BI"           
            aAdd(_aLinhaNF, SD2->D2_ITEM   )                                      // "Item"           
            aAdd(_aLinhaNF, SD2->D2_COD    )                                      // "Produto"           
            aAdd(_aLinhaNF, _cDescPrd      )                                      // "Descrição"   
            aAdd(_aLinhaNF, U_ROMS025I(SD2->D2_PICM,"@E 999,999,999.99")   )       // "Aliq.%"           
            aAdd(_aLinhaNF, U_ROMS025I(SD2->D2_QUANT,"@E 999,999,999.99")  )       // "Qtde"             
			aAdd(_aLinhaNF, SD2->D2_UM     )                                      // "U.M."               
			aAdd(_aLinhaNF, U_ROMS025I(SD2->D2_QTSEGUM,"@E 999,999,999.99"))       // "Qtde 2a U.M."  
    		aAdd(_aLinhaNF, SD2->D2_SEGUM  )                                      // "2a U.M."         
            aAdd(_aLinhaNF, U_ROMS025I(SD2->D2_PRCVEN,"@E 999,999,999.99") )       // "Vlr.Uni."        
            aAdd(_aLinhaNF, U_ROMS025I(SD2->D2_TOTAL,"@E 999,999,999.99")  )       // "Valor Total"     
			aAdd(_aLinhaNF, SD2->D2_NFORI  )                                      // "NF.Origem"       
            aAdd(_aLinhaNF, SD2->D2_SERIORI)                                      // "Serie Origem"  

            aAdd(_aRet, AClone(_aLinhaNF))
                        
            SD2->(DBSkip())
            
         EndDo
	  Else 
         _aLinhaNF := {}
         For _nI := 1 To Len(_aDadosR)
             aAdd(_aLinhaNF, _aDadosR[_nI])
         Next

         If ValType(_aLinhaNF[12]) == "N"
            _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12   Valor total do item.	
	     EndIf
	     If ValType(_aLinhaNF[13]) == "N"
	    	_aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13   Compensação  
	     EndIf	
	     If ValType(_aLinhaNF[14]) == "N"
		    _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14   Desconto do item.							
	     EndIf
	     If ValType(_aLinhaNF[15]) == "N"
	 	    _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15   
	     EndIf
	     If ValType(_aLinhaNF[16]) == "N"
		    _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16   
	     EndIf	
	     If Len(_aLinhaNF) >= 25 .And. ValType(_aLinhaNF[25]) == "N"
	        _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 25   
	     EndIf		
	     If Len(_aLinhaNF) >= 26 .And. ValType(_aLinhaNF[26]) == "N"
	        _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 26   
	     EndIf		
	     If Len(_aLinhaNF) >= 27 .And. ValType(_aLinhaNF[27]) == "N"
	        _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // 27  
	     EndIf	
	     If Len(_aLinhaNF) >= 28 .And. ValType(_aLinhaNF[28]) == "N"
	        _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // 28   
	     EndIf	
	     If Len(_aLinhaNF) >= 30 .And. ValType(_aLinhaNF[30]) == "N"
	        _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // 30   
	     EndIf	
	     If Len(_aLinhaNF) >= 31 .And. ValType(_aLinhaNF[31]) == "N"
	        _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // 31   
	     EndIf	
	     If Len(_aLinhaNF) >= 32 .And. ValType(_aLinhaNF[32]) == "N"
	        _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // 32   
	     EndIf 	

	     If Len(_aLinhaNF) >= 33 .And. ValType(_aLinhaNF[33]) == "N"
	        _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // 33   
	     EndIf 	

         If Len(_aLinhaNF) >= 34 .And. ValType(_aLinhaNF[34]) == "N"
	        _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // 34  
	     EndIf 	

         If Len(_aLinhaNF) >= 35 .And. ValType(_aLinhaNF[35]) == "N"
	        _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // 35   
	     EndIf 	

         If Len(_aLinhaNF) >= 36 .And. ValType(_aLinhaNF[36]) == "N"
	        _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // 36   
	     EndIf 	

         If Len(_aLinhaNF) >= 37 .And. ValType(_aLinhaNF[37]) == "N"
	        _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // 37   
	     EndIf 	

         If Len(_aLinhaNF) >= 38 .And. ValType(_aLinhaNF[38]) == "N"
	        _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // 38   		 
	     EndIf 	
      
	     If Len(_aLinhaNF) >= 39 .And. ValType(_aLinhaNF[39]) == "N"
	        _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // 39   
	     EndIf 	
      
	     If Len(_aLinhaNF) >= 40 .And. ValType(_aLinhaNF[40]) == "N"
	        _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // 40   
	     EndIf 	

         If Len(_aLinhaNF) >= 41 .And. ValType(_aLinhaNF[41]) == "N"
	        _aLinhaNF[41] := U_ROMS025I(_aLinhaNF[41],"@E 999,999,999.999")                    // 41   
	     EndIf 	

	     If Len(_aLinhaNF) >= 42 .And. ValType(_aLinhaNF[42]) == "N"
	        _aLinhaNF[42] := U_ROMS025I(_aLinhaNF[42],"@E 999,999,999.999")                    // 42   
	     EndIf 	

	     If Len(_aLinhaNF) >= 43 .And. ValType(_aLinhaNF[43]) == "N"
	        _aLinhaNF[43] := U_ROMS025I(_aLinhaNF[43],"@E 999,999,999.999")                    // 43   
	     EndIf 	

	     If Len(_aLinhaNF) >= 44 .And. ValType(_aLinhaNF[44]) == "N"
	        _aLinhaNF[44] := U_ROMS025I(_aLinhaNF[44],"@E 999,999,999.999")                    // 44   
	     EndIf 	

	     If Len(_aLinhaNF) >= 45 .And. ValType(_aLinhaNF[45]) == "N"
	        _aLinhaNF[45] := U_ROMS025I(_aLinhaNF[45],"@E 999,999,999.999")                    // 45   
	     EndIf 	

	     If Len(_aLinhaNF) >= 46 .And. ValType(_aLinhaNF[46]) == "N"
	        _aLinhaNF[46] := U_ROMS025I(_aLinhaNF[46],"@E 999,999,999.999")                    // 46   
	     EndIf 	
      
	     aAdd(_aLinhaNF, "" )                                // Mix BI
         aAdd(_aLinhaNF, "" )                                // "Item"           
         aAdd(_aLinhaNF, "" )                                // "Produto"           
         aAdd(_aLinhaNF, "" )                                // "Descrição"        
         aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Aliq.%"           
         aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Qtde"             
         aAdd(_aLinhaNF, "" )                                // "U.M."               
         aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99")) // "Qtde 2a U.M."  
         aAdd(_aLinhaNF, "" )                                // "2a U.M."         
         aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Vlr.Uni."        
         aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Valor Total"     
         aAdd(_aLinhaNF, "" )                                // "NF.Origem"       
         aAdd(_aLinhaNF, "" )                                // "Serie Origem"  
 
         For i := 1 to Len(_aDadosRAD)
            aAdd(_aLinhaNF,_aDadosRAD[i])
         Next

         aAdd(_aRet, AClone(_aLinhaNF))

      EndIf   
   Else
      _aLinhaNF := {}
      For _nI := 1 To Len(_aDadosR)
          aAdd(_aLinhaNF, _aDadosR[_nI])
      Next

      If ValType(_aLinhaNF[12]) == "N"
         _aLinhaNF[12] := U_ROMS025I(_aLinhaNF[12],"@E 999,999,999.999")                    // 12   Valor total do item.	
	  EndIf
	  If ValType(_aLinhaNF[13]) == "N"
		 _aLinhaNF[13] := U_ROMS025I(_aLinhaNF[13],"@E 999,999,999.999")                    // 13   Compensação  
	  EndIf	
	  If ValType(_aLinhaNF[14]) == "N"
		 _aLinhaNF[14] := U_ROMS025I(_aLinhaNF[14],"@E 999,999,999.999")                    // 14   Desconto do item.							
	  EndIf
	  If ValType(_aLinhaNF[15]) == "N"
		 _aLinhaNF[15] := U_ROMS025I(_aLinhaNF[15],"@E 999,999,999.999")                    // 15   
	  EndIf
	  If ValType(_aLinhaNF[16]) == "N"
		 _aLinhaNF[16] := U_ROMS025I(_aLinhaNF[16],"@E 999,999,999.999")                    // 16   
	  EndIf	
	  If Len(_aLinhaNF) >= 25 .And. ValType(_aLinhaNF[25]) == "N"
	     _aLinhaNF[25] := U_ROMS025I(_aLinhaNF[25],"@E 999,999,999.999")                    // 25   
	  EndIf		
	  If Len(_aLinhaNF) >= 26 .And. ValType(_aLinhaNF[26]) == "N"
	     _aLinhaNF[26] := U_ROMS025I(_aLinhaNF[26],"@E 999,999,999.999")                    // 26   
	  EndIf		
	  If Len(_aLinhaNF) >= 27 .And. ValType(_aLinhaNF[27]) == "N"
	     _aLinhaNF[27] := U_ROMS025I(_aLinhaNF[27],"@E 999,999,999.999")                    // 27  
	  EndIf	
	  If Len(_aLinhaNF) >= 28 .And. ValType(_aLinhaNF[28]) == "N"
	     _aLinhaNF[28] := U_ROMS025I(_aLinhaNF[28],"@E 999,999,999.999")                    // 28   
	  EndIf	
	  If Len(_aLinhaNF) >= 30 .And. ValType(_aLinhaNF[30]) == "N"
	     _aLinhaNF[30] := U_ROMS025I(_aLinhaNF[30],"@E 999,999,999.999")                    // 30   
	  EndIf	
	  If Len(_aLinhaNF) >= 31 .And. ValType(_aLinhaNF[31]) == "N"
	     _aLinhaNF[31] := U_ROMS025I(_aLinhaNF[31],"@E 999,999,999.999")                    // 31   
	  EndIf	
	  If Len(_aLinhaNF) >= 32 .And. ValType(_aLinhaNF[32]) == "N"
	     _aLinhaNF[32] := U_ROMS025I(_aLinhaNF[32],"@E 999,999,999.999")                    // 32   
	  EndIf 	

	  If Len(_aLinhaNF) >= 33 .And. ValType(_aLinhaNF[33]) == "N"
	     _aLinhaNF[33] := U_ROMS025I(_aLinhaNF[33],"@E 999,999,999.999")                    // 33   
	  EndIf 	

      If Len(_aLinhaNF) >= 34 .And. ValType(_aLinhaNF[34]) == "N"
	     _aLinhaNF[34] := U_ROMS025I(_aLinhaNF[34],"@E 999,999,999.999")                    // 34  
	  EndIf 	

      If Len(_aLinhaNF) >= 35 .And. ValType(_aLinhaNF[35]) == "N"
	     _aLinhaNF[35] := U_ROMS025I(_aLinhaNF[35],"@E 999,999,999.999")                    // 35   
	  EndIf 	

      If Len(_aLinhaNF) >= 36 .And. ValType(_aLinhaNF[36]) == "N"
	     _aLinhaNF[36] := U_ROMS025I(_aLinhaNF[36],"@E 999,999,999.999")                    // 36   
	  EndIf 	

      If Len(_aLinhaNF) >= 37 .And. ValType(_aLinhaNF[37]) == "N"
	     _aLinhaNF[37] := U_ROMS025I(_aLinhaNF[37],"@E 999,999,999.999")                    // 37   
	  EndIf 	

      If Len(_aLinhaNF) >= 38 .And. ValType(_aLinhaNF[38]) == "N"
	     _aLinhaNF[38] := U_ROMS025I(_aLinhaNF[38],"@E 999,999,999.999")                    // 38   		 
	  EndIf 	
      
	  If Len(_aLinhaNF) >= 39 .And. ValType(_aLinhaNF[39]) == "N"
	     _aLinhaNF[39] := U_ROMS025I(_aLinhaNF[39],"@E 999,999,999.999")                    // 39   
	  EndIf 	
      
	  If Len(_aLinhaNF) >= 40 .And. ValType(_aLinhaNF[40]) == "N"
	     _aLinhaNF[40] := U_ROMS025I(_aLinhaNF[40],"@E 999,999,999.999")                    // 40   
	  EndIf 	

      If Len(_aLinhaNF) >= 41 .And. ValType(_aLinhaNF[41]) == "N"
	     _aLinhaNF[41] := U_ROMS025I(_aLinhaNF[41],"@E 999,999,999.999")                    // 41   
	  EndIf 	

	  If Len(_aLinhaNF) >= 42 .And. ValType(_aLinhaNF[42]) == "N"
	     _aLinhaNF[42] := U_ROMS025I(_aLinhaNF[42],"@E 999,999,999.999")                    // 42   
	  EndIf 	

	  If Len(_aLinhaNF) >= 43 .And. ValType(_aLinhaNF[43]) == "N"
	     _aLinhaNF[43] := U_ROMS025I(_aLinhaNF[43],"@E 999,999,999.999")                    // 43   
	  EndIf 	

	  If Len(_aLinhaNF) >= 44 .And. ValType(_aLinhaNF[44]) == "N"
	     _aLinhaNF[44] := U_ROMS025I(_aLinhaNF[44],"@E 999,999,999.999")                    // 44   
	  EndIf 	

	  If Len(_aLinhaNF) >= 45 .And. ValType(_aLinhaNF[45]) == "N"
	     _aLinhaNF[45] := U_ROMS025I(_aLinhaNF[45],"@E 999,999,999.999")                    // 45   
	  EndIf 	

	  If Len(_aLinhaNF) >= 46 .And. ValType(_aLinhaNF[46]) == "N"
	     _aLinhaNF[46] := U_ROMS025I(_aLinhaNF[46],"@E 999,999,999.999")                    // 46   
	  EndIf 
	  	
      For i := 1 to Len(_aDadosRAD)
         aAdd(_aLinhaNF,_aDadosRAD[i])
      Next
	  
	  aAdd(_aLinhaNF, "" )                                // Mix BI
      aAdd(_aLinhaNF, "" )                                // "Item"           
      aAdd(_aLinhaNF, "" )                                // "Produto"           
      aAdd(_aLinhaNF, "" )                                // "Descrição"        
      aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Aliq.%"           
      aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Qtde"             
      aAdd(_aLinhaNF, "" )                                // "U.M."               
      aAdd(_aLinhaNF, U_ROMS025I(0 ,"@E 999,999,999.99")) // "Qtde 2a U.M."  
      aAdd(_aLinhaNF, "" )                                // "2a U.M."         
      aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Vlr.Uni."        
      aAdd(_aLinhaNF, U_ROMS025I(0,"@E 999,999,999.99"))  // "Valor Total"     
      aAdd(_aLinhaNF, "" )                                // "NF.Origem"       
      aAdd(_aLinhaNF, "" )                                // "Serie Origem"  

      aAdd(_aRet, AClone(_aLinhaNF))
             
   EndIf
  
End Sequence'

RestOrd(_aOrd)

Return _aRet

/*
===============================================================================================================================
Programa--------: ROMS025H
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/03/2019
Descrição-------: Função que Processa a impressão dos dados do relatório - Previsão de Comissão
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS025H(oProc As Object)

Local _cAlias As Character
Local _cAlias3 As Character
Local _cAlias4 As Character
Local _nCountRec As Numeric
Local _nTotreg As Numeric  
Local _cRazaoCli As Character
Local _cCodGrupo  As Character
Local _cDescGrupo  As Character
Local _cMVPAR05  As Character
Local _aDadosIndex As Array
Local _aDadosLin As Array
Local _nI As Numeric
Local _nJ As Numeric 
Local _nTotColun As Numeric
Local _aParcelaPre As Numeric
Local _cParcela As Character
Local _nPercParcela As Numeric
Local _nTotParcela As Numeric
Local _nIcmsRet As Numeric
Local _nValICMParc  As Numeric
Local _nBaseComiss As Numeric
Local _nComiss1 As Numeric 
Local _nComiss2 As Numeric
Local _nComiss3 As Numeric
Local _nComiss4 As Numeric
Local _nPerCom1
Local _nPerCom2 As Numeric
Local _nPerCom3 As Numeric
Local _nPerCom4 As Numeric
Local _aComissao As Numeric

Private _aFiliais As Array        

_cAlias    := GetNextAlias()
_cAlias3   := GetNextAlias()
_cAlias4   := GetNextAlias()
_nCountRec := 0  
_ntotreg  := 0    
_cRazaoCli := ""
_cCodGrupo := ""
_cDescGrupo := ""
_cMVPAR05 := MV_PAR06 // Filtro Vendedor 
_aDadosIndex := {}
_aDadosLin := {}
_nI := 0
_nJ := 0
_nTotColun  := 0
_aParcelaPre := {}
_cParcela  := ""
_nPercParcela := 0
_nTotParcela := 0
_nIcmsRet := 0
_nValICMParc := 0
_nBaseComiss := 0
_nComiss1 := 0
_nComiss2 := 0
_nComiss3 := 0
_nComiss4 := 0
_nPerCom1 := 0
_nPerCom2  := 0
_nPerCom3  := 0
_nPerCom4  := 0
_aComissao := {}

_aFiliais:= {}     

Begin Sequence
   If Empty(MV_PAR01)
	  U_ITMsg("Favor preencher o parâmetro: Mes/Ano antes de imprimir este relatório.","Atenção",,1)
	  Break 
   EndIf
     
   //=======================================================================================================
   // Chama a rotina para selecao dos registros da comissao.												
   //=======================================================================================================
   FWMsgRun(,{|oproc|ROMS025QRY(_cAlias,1,oproc)},"Aguarde....","Filtrando os dados de credito e debito da comissão.")        
	
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())        
	            	
   //=============================================
   //Armazena o numero de registros encontrados.
   //=============================================
   COUNT TO _nCountRec 
		
   DBSelectArea(_cAlias)
   (_cAlias)->(DBGoTop())       
	
   //=============================================
   //Verifica se existem registros selecionados.
   //=============================================
   If (_cAlias)->(!Eof())				
      _nni := 0
      
      While (_cAlias)->(!Eof()) 
         _nni++
         oproc:cCaption := ("Processando dados " + StrZero(_nni,10) + " de " +  StrZero(_nCountRec,10))
         ProcessMessages()
         _lachou := .F.
         
         //================================================
         // Busca dados adicionais
         //================================================
         SF2->(DBSetOrder(1))
         SA3->(DBSetOrder(1))
         If SF2->(DBSeek((_cAlias)->FILIAL+(_cAlias)->NUMERO)) .And. AllTrim((_cAlias)->CODCLI) == AllTrim(SF2->F2_CLIENTE) 
            _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME")
			_cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_GRPVEN")
			_cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
            _ccodrep    := SF2->F2_VEND1
            _cnomerep   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodrep)),SA3->A3_NOME," ")
            _ccodsup    := SF2->F2_VEND4
            _cnomesup   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
            _ccodcoord  := SF2->F2_VEND2
            _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
            _ccodger    := SF2->F2_VEND3
            _cnomeger   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
		
			_cCodGNc    := SF2->F2_VEND5
            _cNomeGnc   := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNc)),SA3->A3_NOME," ")
            _lachou     := .T.
         Else
            _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias)->CODCLI+(_cAlias)->LOJA,"A1_NOME")
			_cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias)->CODCLI+(_cAlias)->LOJA,"A1_GRPVEN")
			_cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
            _ccodrep    := (_cAlias)->CODVEND
            _cnomerep   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodrep)),SA3->A3_NOME," ")
            _ccodsup    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_SUPE")
            _cnomesup   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
            _ccodcoord  := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_SUPER")
            _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
            _ccodger    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_GEREN")
            _cnomeger   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
        
			_cCodGnc    := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_GERNC")
            _cNomeGnc   := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
         EndIf
				
         _ncomsup := 0
		 _ncomcoord := 0
		 _ncomger := 0
		 _ncomrep := 0
		 _nComGnc := 0

		 SE3->(DBSetOrder(1))
		 If SE3->(DBSeek((_cAlias)->FILIAL+(_cAlias)->PREFIXO+(_cAlias)->E3NUMORI+(_cAlias)->PARCELA+(_cAlias)->SEQ))
			While SE3->E3_FILIAL == (_cAlias)->FILIAL .And. ;
			   SE3->E3_PREFIXO == (_cAlias)->PREFIXO .And. ;
			   SE3->E3_NUM == (_cAlias)->E3NUMORI .And. ;
			   SE3->E3_PARCELA == (_cAlias)->PARCELA .And. ;
			   SE3->E3_SEQ == (_cAlias)->SEQ
               
               If SE3->E3_VEND == _ccodrep //Representante
                  _ncomrep := Round(_ncomrep + SE3->E3_COMIS ,3)
               EndIf
			   
			   If SE3->E3_VEND == _ccodsup  //Supervisor
                  _ncomsup := Round(_ncomsup + SE3->E3_COMIS ,3)
               EndIf
               
               If SE3->E3_VEND == _ccodcoord  //Coordenador
                  _ncomcoord := Round(_ncomcoord + SE3->E3_COMIS ,3)
               EndIf

               If SE3->E3_VEND == _ccodger  //Gerente
                  _ncomger := Round(_ncomger + SE3->E3_COMIS ,3)
               EndIf 

			   If SE3->E3_VEND == _cCodGnc  //Gerente Nacional
                  _nComGnc := Round(_nComGnc + SE3->E3_COMIS ,3)
               EndIf

               SE3->(DBSkip())
            EndDo
         EndIf
            
         _nperrep := Round(_ncomrep/(_cAlias)->BASECOMIS*100,3)
         _nperrep := IIf(_nperrep<0,-1*_nperrep,_nperrep)
			
         _nbasecomis := IIf((_cAlias)->COMISSAO<0,-1*(_cAlias)->BASECOMIS,(_cAlias)->BASECOMIS)
				
         _npersup := Round(_ncomsup/(_cAlias)->BASECOMIS*100,3)
         _npersup := IIf(_npersup<0,-1*_npersup,_npersup)
				
         _npercoo := Round(_ncomcoord/(_cAlias)->BASECOMIS*100,3)
         _npercoo := IIf(_npercoo<0,-1*_npercoo,_npercoo)
				
         _nperger := Round(_ncomger/(_cAlias)->BASECOMIS*100,3)
         _nperger := IIf(_nperger<0,-1*_nperger,_nperger)   

         _nPerGnc := Round(_nComGnc/(_cAlias)->BASECOMIS*100,3)
         _nPerGnc := IIf(_nPerGnc<0,-1*_nPerGnc,_nPerGnc)   
				
         _dtemissao := IIf(!Empty((_cAlias)->DTEMISSAO),SToD((_cAlias)->DTEMISSAO),"")
         _dtbaixa := IIf(!Empty((_cAlias)->DTBAIXA),SToD((_cAlias)->DTBAIXA),"")
			
         //verifica se tem duplicata
         If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados
            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == (_cAlias)->NUMERO .And. ;
											_vAux[6]  == (_cAlias)->PARCELA .And. ;
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[37] == (_cAlias)->SEQ })

        ElseIf ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime vendedor   
               ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime supervisor 
               ("G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime Coordenador 
               (! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) .Or. ; // Não imprime gerente 
               ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07)        // Não imprime gerente nacional 

            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == (_cAlias)->NUMERO .And. ;
											_vAux[6]  == (_cAlias)->PARCELA .And. ;
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[33] == (_cAlias)->SEQ })
         Else
            _npl :=  aScan(_aDados,{|_vAux|	_vAux[1]  == (_cAlias)->FILIAL .And. ;
											_vAux[2]  == (_cAlias)->TIPO .And. ;
											_vAux[3]  == _dtemissao .And. ;
											_vAux[4]  == _dtbaixa .And. ;
											_vAux[5]  == (_cAlias)->NUMERO .And. ;
											_vAux[6]  == (_cAlias)->PARCELA .And. ;
											_vAux[7]  == _cCodGrupo .And. ;
											_vAux[8]  == _cDescGrupo .And. ;
											_vAux[9]  == (_cAlias)->CODCLI .And. ;
											_vAux[10] == (_cAlias)->LOJA .And. ;
											_vAux[11] == _cRazaoCli .And. ;
											_vAux[21] == (_cAlias)->SEQ }) 
         EndIf

         If _npl == 0 //Só incrementa se não tiver no array
		    //===============================================
			// Incrementa array para geração de excel
			//===============================================		  	
            If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados
               aAdd(_aDados,{(_cAlias)->FILIAL	,;	             					 //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodsup,;												 //19
							 _cnomesup,;											 //20
							 _ccodcoord,;											 //21
							 _cnomecoord,;											 //22
							 _ccodger,;												 //23
							 _cnomeger,;											 //24
                             _cCodGNc,;                                              //25
							 _cNomeGnc,;                                             //26
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;			 //25-->27
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			 //26-->28
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;			 //27-->29
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			 //28-->30
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 //29-->31
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			 //30-->32
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;			 //31-->33
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			 //32-->34
                             U_ROMS025I(_nComGnc,"@E 999,999,999.999"),;			 //35
							 U_ROMS025I(_nPerGnc,"@E 999,999,999.999"),;			 //36
							 (_cAlias)->SEQ,;                                         //33-->37
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})
							
            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07//  Não imprime vendedor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodsup,;												 //17
							 _cnomesup,;											 //18
							 _ccodcoord,;											 //19
							 _cnomecoord,;											 //20
							 _ccodger,;												 //21
							 _cnomeger,;										     //22
                             _cCodGNc,;                                              //23
							 _cNomeGnc,;                                             //24
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;			 //23-->25
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;			 //24-->26
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		     //25-->27
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			 //26-->28
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;			 //27-->29
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			 //28-->30
                             U_ROMS025I(_nComGnc,"@E 999,999,999.999"),;			 //31
							 U_ROMS025I(_nPerGnc,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //29-->33
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})
            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime supervisor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodcoord,;											 //19
							 _cnomecoord,;											 //20
							 _ccodger,;												 //21
							 _cnomeger,;											 //22
                             _cCodGNc,;                                              //23
							 _cNomeGnc,;                                             //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;			 //23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;			 //24-->26
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 //25-->27
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;			 //26-->28
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;			 //27-->29
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;			 //28-->30
                             U_ROMS025I(_nComGnc,"@E 999,999,999.999"),;			 //31
							 U_ROMS025I(_nPerGnc,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //29-->33
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							 })
            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime Coordenador
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodsup,;												 //19
							 _cnomesup,;										     //20
							 _ccodger,;												 //21
							 _cnomeger,;										     //22
                             _cCodGNc,;                                              //23
							 _cNomeGnc,;                                             //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 //24-->26
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //25-->27
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 //26-->28
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //27-->29
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 //28-->30
                             U_ROMS025I(_nComGnc,"@E 999,999,999.999"),;			 //31
							 U_ROMS025I(_nPerGnc,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //29-->33
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							}) 
            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07// Não imprime gerente
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodsup,;												 //19
							 _cnomesup,;										 	 //20
							 _ccodcoord,;											 //21
							 _cnomecoord,;											 //22
                             _cCodGNc,;                                              //23
							 _cNomeGnc,;                                             //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 //24-->26
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //25-->27
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 //26-->28
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		 	 //27-->29
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 //28-->30
                             U_ROMS025I(_nComGnc,"@E 999,999,999.999"),;			 //31
							 U_ROMS025I(_nPerGnc,"@E 999,999,999.999"),;			 //32
							 (_cAlias)->SEQ,;                                         //29-->33
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							 })
            ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// Não imprime gerente nacional
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 _ccodsup,;												 //19
							 _cnomesup,;										 	 //20
							 _ccodcoord,;											 //21
							 _cnomecoord,;											 //22
							 _ccodger,;												 //23
							 _cnomeger,;										     //24
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //23-->25
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 //24-->26
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //25-->27
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 //26-->28
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;		 	 //27-->29
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 //28-->30
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //31
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 //32
							 (_cAlias)->SEQ,;                                         //29-->33
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							 })

            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas gerente nacional
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _cCodGNc,;                                              //17
			                 _cNomeGnc,;                                             //18
							 U_ROMS025I(_nComGnc,"@E 999,999,999.999"),;			 //19
							 U_ROMS025I(_nPerGnc,"@E 999,999,999.999"),;			 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})
//------------------------------------------------------------------------------------------------------------------------------
            ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07  // imprime apenas gerente
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodger,;												 //17
							 _cnomeger,;											 //18
							 U_ROMS025I(_ncomger,"@E 999,999,999.999"),;				 //19
							 U_ROMS025I(_nperger,"@E 999,999,999.999"),;				 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})
            ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador
           	   aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodcoord,;											 //17
							 _cnomecoord,;											 //18
							 U_ROMS025I(_ncomcoord,"@E 999,999,999.999"),;			 //19
							 U_ROMS025I(_npercoo,"@E 999,999,999.999"),;				 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas supervisor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;							         //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodsup,;												 //17
							 _cnomesup,;											 //18
							 U_ROMS025I(_ncomsup,"@E 999,999,999.999"),;				 //19
							 U_ROMS025I(_npersup,"@E 999,999,999.999"),;				 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})						
            ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor
               aAdd(_aDados,{(_cAlias)->FILIAL	,;						             //01
							 (_cAlias)->TIPO,;										 //02
			 				 _dtemissao,;											 //03
			 				 _dtbaixa,;												 //04
			 				 (_cAlias)->NUMERO,;									 //05
							 (_cAlias)->PARCELA,;									 //06
							 _cCodGrupo ,;											 //07
							 _cDescGrupo,;											 //08
							 (_cAlias)->CODCLI,;									 //09
							 (_cAlias)->LOJA,;										 //10
							 _cRazaoCli,;											 //11
							 U_ROMS025I((_cAlias)->VLRTITULO,"@E 999,999,999.99"),;	 //12
							 U_ROMS025I((_cAlias)->COMPENSACAO,"@E 999,999,999.99"),; //13
							 U_ROMS025I((_cAlias)->DESCONTO,"@E 999,999,999.99"),;	 //14
							 U_ROMS025I((_cAlias)->BAIXASANT,"@E 999,999,999.99"),;	 //15
							 U_ROMS025I(_nbasecomis,"@E 999,999,999.99"),;			 //16
							 _ccodrep,;												 //17
							 _cnomerep,;											 //18
							 U_ROMS025I(_ncomrep,"@E 999,999,999.999"),;				 //19
							 U_ROMS025I(_nperrep,"@E 999,999,999.999"),;				 //20
							 (_cAlias)->SEQ,;                                         //21
                      U_ROMS025I((_cAlias)->(SE5DCT+SE5VRB+COMPENSACAO),"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5DCT,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->SE5VRB,"@E 999,999,999.999"),;
                      U_ROMS025I((_cAlias)->VALST,"@E 999,999,999.999");  
							})							
            Else // Não exibe dados do relatório em excel.
               _aDados := {}		
            EndIf							  	
		 EndIf

		 //=======================================================================================================
		 // Chama a rotina para selecao dos registros da comissao.												
		 //=======================================================================================================
		 MV_PAR06 := (_cAlias)->CODVEND   // Filtro codigo do Vendedor 
		 FWMsgRun(,{|oproc|ROMS025QRY(_cAlias3,3,oproc)},"Aguarde....","Filtrando os dados bonificação.")    
		
		 _nTotReg := 0 
		 		
  		 DBSelectArea(_cAlias3)
		 (_cAlias3)->( DBGoTop() )
		 (_cAlias3)->( DBEval( {|| _nTotReg++ } ) )
		 (_cAlias3)->( DBGoTop() )

		 If _nTotReg > 0
			_nConAux := 0
			While (_cAlias3)->( !Eof() )
			   _nConAux++
			   oproc:cCaption := 'Processando bonificações... ['+ StrZero(_nConAux,9) +'] de ['+ StrZero(_nTotReg,9) +'].'
			   ProcessMessages()

 			   _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias3)->F2_CLIENTE+(_cAlias3)->F2_LOJA,"A1_NOME")
			   _cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias3)->F2_CLIENTE+(_cAlias3)->F2_LOJA,"A1_GRPVEN")
			   _cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
			   _cCodVen := (_cAlias3)->F2_VEND1
			   _ccodsup :=  (_cAlias3)->F2_VEND4
			   _cnomesup := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
			   _ccodcoord := (_cAlias3)->F2_VEND2
			   _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
		       _ccodger := (_cAlias3)->F2_VEND3
			   _cnomeger := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")
			   
			   _cCodGNc  := (_cAlias3)->F2_VEND5
			   _cNomeGnc := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNc)),SA3->A3_NOME," ")

			   If aScan(_aDados, {|_vAux| _vAux[1]==(_cAlias3)->F2_FILIAL .And. _vAux[2]=="BON" .And. _vAux[5]==(_cAlias3)->F2_DOC}) ==  0
				  // Incrementa array para geração de excel
                  If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                          //01
								   "BON",;													                              //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                  //03
								   "  ",;													                              //04
								   (_cAlias3)->F2_DOC,;									                                  //05
								   "  ",;													                              //06
								   _cCodGrupo ,;											                              //07
								   _cDescGrupo,;											                              //08
								   (_cAlias3)->F2_CLIENTE,;								                                  //09
								   (_cAlias3)->F2_LOJA,;									                              //10
								   _cRazaoCli,;											                                  //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									  //12
							       U_ROMS025I(0,"@E 999,999,999.99"),;													  //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													  //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													  //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							      //16
								   _cCodVen,;												                              //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                              //18
								   _ccodsup,;												                              //19
								   _cnomesup,;												                              //20
								   _ccodcoord,;											                                  //21
								   _cnomecoord,;											                              //22
								   _ccodger,;												                              //23
								   _cnomeger,;												                              //24
								   _cCodGNc,;                                                                             //25
			                       _cNomeGnc,;                                                                            //26
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					  //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					  //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					  //29-->31
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //30-->32
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					  //31-->33
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //32-->34
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					  //35
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		  //36
								   " ",;                                                                                   //33-->37
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
								   })

                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
							       DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodsup,;												                               //17
								   _cnomesup,;												                               //18
								   _ccodcoord,;											                                   //19
								   _cnomecoord,;											                               //20
								   _ccodger,;												                               //21
								   _cnomeger,;												                               //22
								   _cCodGNc,;                                                                              //23
			                       _cNomeGnc,;                                                                             //24
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //32
								   " ",;                                                                                    //29-->33
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
							       })

                  ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodcoord,;											                                   //19
								   _cnomecoord,;											                               //20
								   _ccodger,;												                               //21
								   _cnomeger,;												                               //22
								   _cCodGNc,;                                                                              //23
			                       _cNomeGnc,;                                                                             //24
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //32
								   " ",;                                                                                    //29-->33
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
							 	   })

                  ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime Coordenador
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodsup,;												                               //19
								   _cnomesup,;												                               //20
								   _ccodger,;												                               //21
								   _cnomeger,;												                               //22 
								   _cCodGNc,;                                                                              //23
			                       _cNomeGnc,;                                                                             //24
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //32
								   " ",;                                                                                    //29-->33
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
								   })

                  ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodsup,;												                               //19
								   _cnomesup,;												                               //20
								   _ccodcoord,;											                                   //21
								   _cnomecoord,;											                               //22
								   _cCodGNc,;                                                                              //23
			                       _cNomeGnc,;                                                                             //24
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //32
								   " ",;                                                                                    //29-->33
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
								   })

//-------------------------------------------------------------------------------------------------------------------------------
ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // Não imprime gerente nacional.
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   _ccodsup,;												                               //19
								   _cnomesup,;												                               //20
								   _ccodcoord,;											                                   //21
								   _cnomecoord,;											                               //22
								   _ccodger,;												                               //23
								   _cnomeger,;												                               //24 
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //23-->25
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //24-->26
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //25-->27
								   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //26-->28
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //27-->29
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //28-->30
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //31
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //32
								   " ",;                                                                                    //29-->33
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
								   })
//-------------------------------------------------------------------------------------------------------------------------------
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas gerente nacional
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodGNc,;                                                                              //17
			                       _cNomeGnc,;                                                                             //18
								   U_ROMS025I(Round((_cAlias3)->COMIS5/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS5/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //20
								   " ",;                                                                                    //21
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
							    	})
//-----------------------------------------------------------------------------------------------------------------------------------------------
                  ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas gerente
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodger,;												                               //17
								   _cnomeger,;												                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS3/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS3/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;                                                                                    //21
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
							    	})
                  ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
							       "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodcoord,;											                                   //17
								   _cnomecoord,;											                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS2/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS2/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;		   //20
								   " ",;                                                                                    //21
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
								   })
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas supervisor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _ccodsup,;												                               //17
								   _cnomesup,;												                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS4/-100,3),"@E 999,999,999.999"),;					   //19
				    			   U_ROMS025I(Round((_cAlias3)->COMIS4/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //20
								   " ",;                                                                                    //21
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
								   })
                  ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor
				     aAdd(_aDados,{(_cAlias3)->F2_FILIAL	,;					                                           //01
								   "BON",;													                               //02
								   DToC(SToD((_cAlias3)->F2_EMISSAO)),;					                                   //03
								   "  ",;													                               //04
								   (_cAlias3)->F2_DOC,;									                                   //05
								   "  ",;													                               //06
								   _cCodGrupo ,;											                               //07
								   _cDescGrupo,;											                               //08
								   (_cAlias3)->F2_CLIENTE,;								                                   //09
								   (_cAlias3)->F2_LOJA,;									                               //10
								   _cRazaoCli,;											                                   //11
								   U_ROMS025I((_cAlias3)->VALTOT,"@E 999,999,999.99"),;									   //12
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
								   U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
								   U_ROMS025I((_cAlias3)->VALTOT*-1,"@E 999,999,999.99"),;							       //16
								   _cCodVen,;												                               //17
								   Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
								   U_ROMS025I(Round((_cAlias3)->COMIS1/-100,3),"@E 999,999,999.999"),;					   //19
								   U_ROMS025I(Round((_cAlias3)->COMIS1/(_cAlias3)->VALTOT,3),"@E 999,999,999.999"),;	   //20
								   " ",;                                                                                    //21
                            U_ROMS025I((_cAlias3)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias3)->VALST,"@E 999,999,999.999");  
							 	   })
                  Else // Não exibe dados do relatório em excel.
                     _aDados := {}		
                  EndIf
			   EndIf
			   
			   (_cAlias3)->( DBSkip() )
			EndDo
		 EndIf					
		 
		 (_cAlias)->(DBSkip())
		 
	  EndDo

   EndIf
   
   MV_PAR06 := _cMVPAR05   // Filtro Vendedor 
   
   //=======================================================================================================
   // Chama a rotina para selecao dos registros da previsão de comissao.												
   //=======================================================================================================
   //MV_PAR06 := (_cAlias)->CODVEND   // Filtro codigo do Vendedor 
   FWMsgRun(,{|oproc|ROMS025QRY(_cAlias4,4,oproc)},"Aguarde....","Filtrando os dados Previsão de Comissão")    
		
   _nTotReg := 0 
		 		
   DBSelectArea(_cAlias4)
   (_cAlias4)->( DBGoTop() )
   (_cAlias4)->( DBEval( {|| _nTotReg++ } ) )
   (_cAlias4)->( DBGoTop() )

   If _nTotReg > 0
	  _nConAux := 0
	  While (_cAlias4)->( !Eof() )
         _nConAux++
		 oproc:cCaption := 'Processando dados previsão de comissões... ['+ StrZero(_nConAux,9) +'] de ['+ StrZero(_nTotReg,9) +'].'
		 ProcessMessages()

 		 _cRazaoCli  := Posicione("SA1",1,xFilial("SA1")+(_cAlias4)->F2_CLIENTE+(_cAlias4)->F2_LOJA,"A1_NOME")
	     _cCodGrupo  := Posicione("SA1",1,xFilial("SA1")+(_cAlias4)->F2_CLIENTE+(_cAlias4)->F2_LOJA,"A1_GRPVEN")
	     _cDescGrupo := Posicione("ACY",1,xFilial("ACY")+_cCodGrupo,"ACY_DESCRI")
		 _cCodVen := (_cAlias4)->F2_VEND1
		 _ccodsup :=  (_cAlias4)->F2_VEND4
		 _cnomesup := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodsup)),SA3->A3_NOME," ")
		 _ccodcoord := (_cAlias4)->F2_VEND2
		 _cnomecoord := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodcoord)),SA3->A3_NOME," ")
		 _ccodger := (_cAlias4)->F2_VEND3
		 _cnomeger := IIf(SA3->(DBSeek(xFilial("SA3")+_ccodger)),SA3->A3_NOME," ")

         _cCodGNc  := (_cAlias4)->F2_VEND5
		 _cNomeGnc := IIf(SA3->(DBSeek(xFilial("SA3")+_cCodGNc)),SA3->A3_NOME," ")

		_aParcelaPre := ROMS025P((_cAlias4)->F2_FILIAL, (_cAlias4)->F2_CLIENTE, (_cAlias4)->F2_LOJA, (_cAlias4)->F2_SERIE, (_cAlias4)->F2_DOC)
		_nTotParcela := Len(_aParcelaPre)
         
		For _nI := 1 To _nTotParcela

		    _cParcela     := _aParcelaPre[_nI,1]
		    _nPercParcela := _aParcelaPre[_nI,2]
			_nPerCom1     := _aParcelaPre[_nI,3]     
			_nPerCom2     := _aParcelaPre[_nI,4]
			_nPerCom3     := _aParcelaPre[_nI,5]
			_nPerCom4     := _aParcelaPre[_nI,6]
			_nValorTit    := _aParcelaPre[_nI,7]
			_nSaldo       := _aParcelaPre[_nI,8]

			_nPercRest    := _nSaldo / _nValorTit
			
			_nIcmsRet    := (_cAlias4)->ICMSRET   
		    _nValICMParc := _nIcmsRet * _nPercParcela 
			_nValICMParc := _nValICMParc * _nPercRest
			//_nBaseComiss := ((_cAlias4)->BASECOMIS + _nIcmsRet) - _nValICMParc
            _nBaseComiss  := _nSaldo - _nValICMParc

            _aComissao := ROMS025R(_cParcela, _nBaseComiss, _nPercParcela ,(_cAlias4)->F2_FILIAL, (_cAlias4)->F2_CLIENTE, (_cAlias4)->F2_LOJA, (_cAlias4)->F2_SERIE, (_cAlias4)->F2_DOC)

			_nComiss1 := _aComissao[2]
			_nPerCom1 := _aComissao[3]
			_nComiss2 := _aComissao[4]
			_nPerCom2 := _aComissao[5]
			_nComiss3 := _aComissao[6]
			_nPerCom3 := _aComissao[7]
			_nComiss4 := _aComissao[8]
			_nPerCom4 := _aComissao[9]

            _nComiss5 := _aComissao[10]
			_nPerCom5 := _aComissao[11] 


		     If aScan(_aDados, {|_vAux| _vAux[1]==(_cAlias4)->F2_FILIAL .And. _vAux[2]=="PRE" .And. _vAux[5]==(_cAlias4)->F2_DOC .And. _vAux[6] == _cParcela }) ==  0
			    // Incrementa array para geração de excel
                If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                              //01
			 		             "PRE",;													                              //02
							     DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                  //03
							     "  ",;													                                  //04
							     (_cAlias4)->F2_DOC,;									                                  //05
							     _cParcela,;											                                  //06
							     _cCodGrupo ,;											                                  //07
							     _cDescGrupo,;											                                  //08
							     (_cAlias4)->F2_CLIENTE,;								                                  //09
							     (_cAlias4)->F2_LOJA,;									                                  //10
							     _cRazaoCli,;											                                  //11
							     U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela , "@E 999,999,999.99"),;					  //12
							     U_ROMS025I(0,"@E 999,999,999.99"),;													  //13
							     U_ROMS025I(0,"@E 999,999,999.99"),;													  //14
							     U_ROMS025I(0,"@E 999,999,999.99"),;													  //15
							     U_ROMS025I(_nBaseComiss, "@E 999,999,999.99"),;				                          //16  // U_ROMS025I(_nBaseComiss * _nPercParcela ,"@E 999,999,999.99"),;	
							     _cCodVen,;												                                  //17
							     Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                                  //18
							     _ccodsup,;												                                  //19
							     _cnomesup,;												                              //20
							     _ccodcoord,;											                                  //21
							     _cnomecoord,;											                                  //22
							     _ccodger,;												                                  //23
							     _cnomeger,;												                              //24
                                 _cCodGNc,;                                                                               //25
			                     _cNomeGnc,;                                                                              //26
							     U_ROMS025I(Round( _nComiss1 , 3)  ,"@E 999,999,999.999")     ,;	                      //25-->27  
							     U_ROMS025I(Round( _nPerCom1 , 3)  ,"@E 999,999,999.999")     ,;                          //26-->28  
							     U_ROMS025I(Round( _nComiss4 , 3)  ,"@E 999,999,999.999")     ,;	                      //27-->29  
							     U_ROMS025I(Round( _nPerCom4 , 3)  ,"@E 999,999,999.999")     ,;	                      //28-->30  
							     U_ROMS025I(Round( _nComiss2 , 3)  ,"@E 999,999,999.999")     ,;	                      //29-->31  
							     U_ROMS025I(Round( _nPerCom2 , 3)  ,"@E 999,999,999.999")     ,;	                      //30-->32  
							     U_ROMS025I(Round( _nComiss3 , 3)  ,"@E 999,999,999.999")     ,;		                  //31-->33  
								 U_ROMS025I(Round( _nPerCom3 , 3)  ,"@E 999,999,999.999")     ,;	                      //32-->34
								 U_ROMS025I(Round( _nComiss5 , 3)  ,"@E 999,999,999.999")     ,;		                  //35  
								 U_ROMS025I(Round( _nPerCom5 , 3)  ,"@E 999,999,999.999")     ,;	                      //36  
                         "  ",;
                           U_ROMS025I(0,"@E 999,999,999.99"),; //37
                           U_ROMS025I(0,"@E 999,999,999.99"),; //38
                           U_ROMS025I(0,"@E 999,999,999.99"),; //39
                           U_ROMS025I(0,"@E 999,999,999.99"),; //40
                           U_ROMS025I(0,"@E 999,999,999.99"); //41
							     })
							  
                ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
					    	     "PRE",;													                               //02
							     DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							     "  ",;													                                   //04
							     (_cAlias4)->F2_DOC,;									                                   //05
							     _cParcela,;											                                   //06
							     _cCodGrupo ,;											                                   //07
							     _cDescGrupo,;											                                   //08
							     (_cAlias4)->F2_CLIENTE,;								                                   //09
							     (_cAlias4)->F2_LOJA,;									                                   //10
							     _cRazaoCli,;											                                   //11
							     U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							     U_ROMS025I(_nBaseComiss ,"@E 999,999,999.99"),;						                   //16  // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;	
							     _ccodsup,;												                                   //17
							     _cnomesup,;												                               //18
							     _ccodcoord,;											                                   //19
							     _cnomecoord,;											                                   //20
							     _ccodger,;												                                   //21
							     _cnomeger,;												                               //22
								 _cCodGNc,;                                                                                //23
			                     _cNomeGnc,;                                                                               //24
							     U_ROMS025I(Round(_nComiss4 ,3),"@E 999,999,999.999"),;				                       //23-->25
							     U_ROMS025I(Round(_nPerCom4 ,3),"@E 999,999,999.999"),;	                                   //24-->26
							     U_ROMS025I(Round(_nComiss2 ,3),"@E 999,999,999.999"),;				                       //25-->27
							     U_ROMS025I(Round(_nPerCom2 ,3),"@E 999,999,999.999"),;	                                   //26-->28 
						         U_ROMS025I(Round(_nComiss3 ,3),"@E 999,999,999.999"),;				                       //27-->29 
							     U_ROMS025I(Round(_nPerCom3 ,3),"@E 999,999,999.999"),;	                                   //28-->30 
								 U_ROMS025I(Round(_nComiss5 ,3),"@E 999,999,999.999"),;				                       //31 
							     U_ROMS025I(Round(_nPerCom5 ,3),"@E 999,999,999.999"),;	                                   //32 
							      " ",;                                                                                     //29-->33
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							     })
                ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
				    	 	     "PRE",;													                               //02
							     DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							     "  ",;													                                   //04
							     (_cAlias4)->F2_DOC,;									                                   //05
							     _cParcela,;											                                   //06
							     _cCodGrupo ,;											                                   //07
							     _cDescGrupo,;											                                   //08
							     (_cAlias4)->F2_CLIENTE,;								                                   //09
							     (_cAlias4)->F2_LOJA,;									                                   //10
							     _cRazaoCli,;											                                   //11
							     U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							     U_ROMS025I(_nBaseComiss ,"@E 999,999,999.99"),;						                   //16  // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;	
							     _cCodVen,;												                                   //17
							     Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                                   //18
							     _ccodcoord,;											                                   //19
							     _cnomecoord,;											                                   //20
							     _ccodger,;												                                   //21
							     _cnomeger,;												                               //22
								 _cCodGNc,;                                                                                //23
			                     _cNomeGnc,;                                                                               //24
						         U_ROMS025I(Round(_nComiss1 ,3),"@E 999,999,999.999"),;				                       //23-->25 
							     U_ROMS025I(Round(_nPerCom1 ,3),"@E 999,999,999.999"),;	                                   //24-->26 
							     U_ROMS025I(Round(_nComiss2 ,3),"@E 999,999,999.999"),;				                       //25-->27 
							     U_ROMS025I(Round(_nPerCom2 ,3),"@E 999,999,999.999"),;	                                   //26-->28 
							     U_ROMS025I(Round(_nComiss3 ,3),"@E 999,999,999.999"),;				                       //27-->29 
							     U_ROMS025I(Round(_nPerCom3 ,3),"@E 999,999,999.999"),;	                                   //28-->30 
                                 U_ROMS025I(Round(_nComiss5 ,3),"@E 999,999,999.999"),;				                       //31 
							     U_ROMS025I(Round(_nPerCom5 ,3),"@E 999,999,999.999"),;	                                   //32  
							     " ",;                                                                                      //29-->33
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							    })
                ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime Coordenador
				   aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
								"PRE",;													                                   //02
								DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
								"  ",;													                                   //04
								(_cAlias4)->F2_DOC,;									                                   //05
								_cParcela,;												                                   //06
								_cCodGrupo ,;											                                   //07
								_cDescGrupo,;											                                   //08
								(_cAlias4)->F2_CLIENTE,;								                                   //09
								(_cAlias4)->F2_LOJA,;									                                   //10
								_cRazaoCli,;											                                   //11
								U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
								U_ROMS025I(0,"@E 999,999,999.99"),;													       //13
								U_ROMS025I(0,"@E 999,999,999.99"),;													       //14
								U_ROMS025I(0,"@E 999,999,999.99"),;													       //15
								U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;						                       //16 // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;						       //16 
								_cCodVen,;												                                   //17
								Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                                   //18
								_ccodsup,;												                                   //19
								_cnomesup,;												                                   //20
								_ccodger,;												                                   //21
								_cnomeger,;												                                   //22
                                _cCodGNc,;                                                                                 //23
			                    _cNomeGnc,;                                                                                //24
								U_ROMS025I(Round(_nComiss1 ,3),"@E 999,999,999.999"),;				                       //23-->25 
								U_ROMS025I(Round(_nPerCom1 ,3),"@E 999,999,999.999"),;	                                   //24-->26 
								U_ROMS025I(Round(_nComiss4 ,3),"@E 999,999,999.999"),;				                       //25-->27 
								U_ROMS025I(Round(_nPerCom4 ,3),"@E 999,999,999.999"),;	                                   //26-->28 
								U_ROMS025I(Round(_nComiss3 ,3),"@E 999,999,999.999"),;				                       //27-->29 
								U_ROMS025I(Round(_nPerCom3 ,3),"@E 999,999,999.999"),;	                                   //28-->30
                                U_ROMS025I(Round(_nComiss5 ,3),"@E 999,999,999.999"),;				                       //31 
							    U_ROMS025I(Round(_nPerCom5 ,3),"@E 999,999,999.999"),;	                                   //32  
								" ",;                                                                                       //29-->33
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
								})
                ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
						         "PRE",;													                               //02
							      DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							      "  ",;													                               //04
							      (_cAlias4)->F2_DOC,;									                                   //05
							      _cParcela,;												                               //06
							      _cCodGrupo ,;											                                   //07
							      _cDescGrupo,;											                                   //08
							      (_cAlias4)->F2_CLIENTE,;								                                   //09
							      (_cAlias4)->F2_LOJA,;									                                   //10
							      _cRazaoCli,;											                                   //11
							      U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							      U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;					                       //16 // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;
							      _cCodVen,;												                               //17
							      Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
							      _ccodsup,;												                               //19
							      _cnomesup,;												                               //20
							      _ccodcoord,;											                                   //21
							      _cnomecoord,;											                                   //22
                                  _cCodGNc,;                                                                               //23
			                      _cNomeGnc,;                                                                              //24
							      U_ROMS025I(Round(_nComiss1 ,3),"@E 999,999,999.999"),;				                   //23-->25 
							      U_ROMS025I(Round(_nPerCom1 ,3),"@E 999,999,999.999"),;	                               //24-->26 
							      U_ROMS025I(Round(_nComiss4 ,3),"@E 999,999,999.999"),;				                   //25-->27 
								  U_ROMS025I(Round(_nPerCom4 ,3),"@E 999,999,999.999"),;	                               //26-->28  
							      U_ROMS025I(Round(_nComiss2 ,3),"@E 999,999,999.999"),;				                   //27-->29 
							      U_ROMS025I(Round(_nPerCom2 ,3),"@E 999,999,999.999"),;	                               //28-->30
                                  U_ROMS025I(Round(_nComiss5 ,3),"@E 999,999,999.999"),;		                           //31 
							      U_ROMS025I(Round(_nPerCom5 ,3),"@E 999,999,999.999"),;	                               //32  
							      " ",;                                                                                     //29-->33
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
								  })       
                ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // Não imprime gerente nacional
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
						         "PRE",;													                               //02
							      DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							      "  ",;													                               //04
							      (_cAlias4)->F2_DOC,;									                                   //05
							      _cParcela,;												                               //06
							      _cCodGrupo ,;											                                   //07
							      _cDescGrupo,;											                                   //08
							      (_cAlias4)->F2_CLIENTE,;								                                   //09
							      (_cAlias4)->F2_LOJA,;									                                   //10
							      _cRazaoCli,;											                                   //11
							      U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							      U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;					                       //16 
							      _cCodVen,;												                               //17
							      Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                               //18
							      _ccodsup,;												                               //19
							      _cnomesup,;												                               //20
							      _ccodcoord,;											                                   //21
							      _cnomecoord,;											                                   //22
                                  _ccodger,;												                               //23
								  _cnomeger,;	                                                                           //24
							      U_ROMS025I(Round(_nComiss1 ,3),"@E 999,999,999.999"),;				                   //23-->25 
							      U_ROMS025I(Round(_nPerCom1 ,3),"@E 999,999,999.999"),;	                               //24-->26 
							      U_ROMS025I(Round(_nComiss4 ,3),"@E 999,999,999.999"),;				                   //25-->27 
								  U_ROMS025I(Round(_nPerCom4 ,3),"@E 999,999,999.999"),;	                               //26-->28  
							      U_ROMS025I(Round(_nComiss2 ,3),"@E 999,999,999.999"),;				                   //27-->29 
							      U_ROMS025I(Round(_nPerCom2 ,3),"@E 999,999,999.999"),;	                               //28-->30
                                  U_ROMS025I(Round(_nComiss3 ,3),"@E 999,999,999.999"),;				                   //27-->29 
							      U_ROMS025I(Round(_nPerCom3 ,3),"@E 999,999,999.999"),;                                   //28-->30
							      " ",;                                                                                     //29-->33
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
								  })       

                ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // imprime apenas gerente nacional
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
						          "PRE",;													                               //02
							      DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							      "  ",;													                               //04
							      (_cAlias4)->F2_DOC,;									                                   //05
							      _cParcela,;												                               //06
							      _cCodGrupo ,;											                                   //07
							      _cDescGrupo,;											                                   //08
							      (_cAlias4)->F2_CLIENTE,;								                                   //09
							      (_cAlias4)->F2_LOJA,;									                                   //10
							      _cRazaoCli,;											                                   //11
							      U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							      U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;					                       //16
							      _cCodGNc,;                                                                               //17
			                      _cNomeGnc,;                                                                              //18
                                  U_ROMS025I(Round(_nComiss5 ,3),"@E 999,999,999.999"),;		                           //19 
							      U_ROMS025I(Round(_nPerCom5 ,3),"@E 999,999,999.999"),;	                               //20  
							      " ",;                                                                                     //21
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							 })
                ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas gerente
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
						          "PRE",;													                               //02
							      DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							      "  ",;													                               //04
							      (_cAlias4)->F2_DOC,;									                                   //05
							      _cParcela,;												                               //06
							      _cCodGrupo ,;											                                   //07
							      _cDescGrupo,;											                                   //08
							      (_cAlias4)->F2_CLIENTE,;								                                   //09
							      (_cAlias4)->F2_LOJA,;									                                   //10
							      _cRazaoCli,;											                                   //11
							      U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							      U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							      U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;					                       //16
							      _ccodger,;												                               //17
							      _cnomeger,;												                               //18
							      U_ROMS025I(Round(_nComiss3 ,3),"@E 999,999,999.999"),;				                   //19 
							      U_ROMS025I(Round(_nPerCom3 ,3),"@E 999,999,999.999"),;	                               //20 
							      " ",;                                                                                     //21
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							 })
                ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
							     "PRE",;													                               //02
							     DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							     "  ",;													                                   //04
							     (_cAlias4)->F2_DOC,;									                                   //05
							     _cParcela,;											                                   //06
							     _cCodGrupo ,;											                                   //07
							     _cDescGrupo,;											                                   //08
							     (_cAlias4)->F2_CLIENTE,;								                                   //09
							     (_cAlias4)->F2_LOJA,;									                                   //10
							     _cRazaoCli,;											                                   //11
							     U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							     U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;						                       //16 // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;	
							     _ccodcoord,;											                                   //17
							     _cnomecoord,;											                                   //18
							     U_ROMS025I(Round(_nComiss2 ,3),"@E 999,999,999.999"),;				                       //19 
							     U_ROMS025I(Round(_nPerCom2 ,3),"@E 999,999,999.999"),;                                    //20 
							     " ",;                                                                                      //21
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							     })
                ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas supervisor
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
						         "PRE",;													                               //02
							     DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							     "  ",;													                                   //04
							     (_cAlias4)->F2_DOC,;									                                   //05
							     _cParcela,;											                                   //06
							     _cCodGrupo ,;											                                   //07
							     _cDescGrupo,;											                                   //08
							     (_cAlias4)->F2_CLIENTE,;								                                   //09
							     (_cAlias4)->F2_LOJA,;									                                   //10
							     _cRazaoCli,;											                                   //11
							    U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							    U_ROMS025I(0,"@E 999,999,999.99"),;													       //13
							    U_ROMS025I(0,"@E 999,999,999.99"),;													       //14
							    U_ROMS025I(0,"@E 999,999,999.99"),;													       //15
							    U_ROMS025I(_nBaseComiss,"@E 999,999,999.99"),;						                       //16 // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;
							    _ccodsup,;												                                   //17
							    _cnomesup,;												                                   //18
							    U_ROMS025I(Round(_nComiss4 ,3),"@E 999,999,999.999"),;				                       //19 
				    		    U_ROMS025I(Round(_nPerCom4 ,3),"@E 999,999,999.999"),;	                                   //20 
							    " ",;                                                                                       //21
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							    })
                ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor
			       aAdd(_aDados,{(_cAlias4)->F2_FILIAL	,;					                                               //01
					     	     "PRE",;													                               //02
						    	 DToC(SToD((_cAlias4)->F2_EMISSAO)),;					                                   //03
							     "  ",;													                                   //04
							     (_cAlias4)->F2_DOC,;									                                   //05
							     _cParcela,;											                                   //06
							     _cCodGrupo ,;											                                   //07
							     _cDescGrupo,;											                                   //08
							    (_cAlias4)->F2_CLIENTE,;								                                   //09
							    (_cAlias4)->F2_LOJA,;									                                   //10
							     _cRazaoCli,;											                                   //11
							     U_ROMS025I((_cAlias4)->VALTOT * _nPercParcela,"@E 999,999,999.99"),;					   //12
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //13
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //14
							     U_ROMS025I(0,"@E 999,999,999.99"),;													   //15
							     U_ROMS025I(_nBaseComiss ,"@E 999,999,999.99"),;						                   //16 // U_ROMS025I(_nBaseComiss * _nPercParcela,"@E 999,999,999.99"),;	
							     _cCodVen,;												                                   //17
							     Posicione("SA3",1,xFilial("SA3")+_cCodVen,"A3_NOME"),;	                                   //18
							     U_ROMS025I(Round(_nComiss1 ,3),"@E 999,999,999.999"),;				                       //19 
							     U_ROMS025I(Round(_nPerCom1 ,3),"@E 999,999,999.999"),;                                    //20 
							     " ",;                                                                                      //21
                            U_ROMS025I((_cAlias4)->(SE5DCT+SE5VRB),"@E 999,999,999.999"),;//U_ROMS025I((_cAlias4)->VALDCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5DCT,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->SE5VRB,"@E 999,999,999.999"),;
                            U_ROMS025I((_cAlias4)->VALST,"@E 999,999,999.999");   
							 })
               EndIf
		    EndIf
		Next //EndIf	   
		 (_cAlias4)->( DBSkip() )
	  EndDo
   EndIf					

   //========================================================================================
   // Ordena os dados do Array _aDados.
   //========================================================================================
   // _aDadosIndex, _aDadosLin, _nI, _nJ, _nTotColun   
   If Len(_aDados) > 0
      _nTotColun := Len(_aDados[1])
      _aDadosIndex := {}
      
      For _nI := 1 To Len(_aDados) 
          _aDadosLin := {}
          For _nJ := 1 To _nTotColun
              aAdd(_aDadosLin, _aDados[_nI,_nJ])
          Next
          
          If AllTrim(_aDados[_nI,2]) == "NF"
             aAdd(_aDadosLin, "1") // Primeira linha na ordenação. 
          ElseIf AllTrim(_aDados[_nI,2]) == "PRE"          
             aAdd(_aDadosLin, "2") // Segunda linha na ordenação. 
          ElseIf AllTrim(_aDados[_nI,2]) == "BON"          
             aAdd(_aDadosLin, "3") // Segunda linha na ordenação. 
          ElseIf AllTrim(_aDados[_nI,2]) == "NCC"          
             aAdd(_aDadosLin, "9") // Segunda linha na ordenação. 
          Else         
             aAdd(_aDadosLin, "9") // Ultima linha na ordenação. 
          EndIf
          
          aAdd(_aDadosIndex,_aDadosLin) 
      Next
   
      _nTotColun += 1
      
      _aDadosIndex := aSort(_aDadosIndex,,,{|x,y| x[1]+x[5]+x[_nTotColun] < y[1]+y[5]+y[_nTotColun] })
      
      _nTotColun -= 1
      
      _aDados := {}
      
      For _nI := 1 To Len(_aDadosIndex) 
          _aDadosLin := {}
      
          For _nJ := 1 To _nTotColun
              aAdd(_aDadosLin, _aDadosIndex[_nI,_nJ])
          Next

          aAdd(_aDados , _aDadosLin) 
      Next
   
   EndIf		 

End Sequence

MV_PAR06 := _cMVPAR05   // Filtro Vendedor 

//==========================
//Finaliza o alias criado.
//==========================
DBSelectArea(_cAlias)
(_cAlias)->(DBCloseArea())    

Return 

/*
===============================================================================================================================
Programa--------: ROMS025V
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/03/2019
Descrição-------: Validar a digitação da data final de Previsão de Comissão.
Parametros------: _cCampo = Campo que disparou a validação.
Retorno---------: .T. / .F.
===============================================================================================================================
*/
User Function ROMS025V(_cCampo As Character) As Logical
Local _lRet As Logical

_lRet := .T.

Begin Sequence
   If _cCampo == "MV_PAR09"
      If MV_PAR08 <> 3 .And. ! Empty(MV_PAR09)
         U_ITMsg("A data final de previsão de comissão deve ser preenchida apenas quando o tipo de emissão de relatório For 'Previsão de Comissão'.","Atenção", ,1) 
         _lRet := .F.
      EndIf
   EndIf
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: ROMS025C
Autor-----------: Julio de Paula Paz
Data da Criacao-: 03/05/2019
Descrição-------: Monta o Cabeçalho dos Relatórios "Baixa Vendedor" e "Previsão de Comissão".
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS025C()

Begin Sequence
   //===========================================================================================
   //   TÍTULOS UTILIZADOS NOS RELATÓRIO BAIXA VENDEDOR E PREVISÃO DE COMISSÃO
   //===========================================================================================
   If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07) // Imprime todos os dados
	  _aTitulo := {	"Filial"		,;			//01
	       			"Tipo"			,;			//02
		    		"Dt. Emissão"	,;			//03
		 	    	"Dt. Baixa"		,;			//04
		 	    	"Documento"		,;			//05
			    	"Parcela"		,;			//06
			    	"Rede"			,;			//07
		    		"Desc Rede"		,;			//08
		   			"Cliente"		,;			//09
		   			"Loja"			,;			//10
		   			"Razão Social"	,;			//11
		   			"Valor Original",;			//12
		   			"Vlr Compensado",;			//13
		   			"Vlr Desconto"	,;			//14
		   			"Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Coordenador" 	,;			//21
				    "Nome cood."    ,;			//22
				    "Gerente" 		,;			//23
				    "Nome ger."     ,;			//24
                    "Gerente Nac."  ,;			//25
				    "Nome ger.Nac." ,;			//26
				    "Vlr Com Rep"	,;			//25-->27
				    "% Com Rep"		,;			//26-->28
				    "Vlr Com Sup"	,;			//27-->29
				    "% Com Sup"		,;			//28-->30
				    "Vlr Com Cood"	,;			//29-->31
				    "% Com Cood"	,;			//30-->32
				    "Vlr Com Ger"	,;			//31-->33
				    "% Com Ger"		 ,;			//32-->34
					"Vlr Com Ger.Nac",;			//35
				    "% Com Ger.Nac"	 ,;			//36
				    "Sequenc.Comissão",;         //33-->37 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				   }		
          
   ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07 //  Não imprime vendedor
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
				    "Dt. Emissão"	,;			//03
				    "Dt. Baixa"		,;			//04
				    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Supervisor" 	,;			//17
				    "Nome sup."     ,;			//18
				    "Coordenador" 	,;			//19
				    "Nome cood."    ,;			//20
				    "Gerente" 		,;			//21
				    "Nome ger."     ,;			//22
					"Gerente Nac."  ,;			//23
				    "Nome ger.Nac"  ,;			//24
				    "Vlr Com Sup"	,;			//23-->25 
				    "% Com Sup"		,;			//24-->26
				    "Vlr Com Cood"	,;			//25-->27
				    "% Com Cood"	,;			//26-->28
				    "Vlr Com Ger"	,;			//27-->29
				    "% Com Ger"		,;			//28-->30
					"Vlr Com Ger.Nac",;			//31
				    "% Com Ger.Nac"	 ,;			//32
				    "Sequenc.Comissão",;         //29-->33
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
      
   ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 // Não imprime supervisor
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 	     	"Dt. Emissão"	,;			//03
		 	    	"Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Coordenador" 	,;			//19
				    "Nome cood."    ,;			//20
				    "Gerente" 		,;			//21
				    "Nome ger."     ,;			//22
				    "Gerente Nac."  ,;			//23
				    "Nome ger.Nac"  ,;			//24
				    "Vlr Com Rep"	,;			//23-->25
				    "% Com Rep"		,;			//24-->26
				    "Vlr Com Cood"	,;			//25-->27
				    "% Com Cood"	,;			//26-->28
				    "Vlr Com Ger"	,;			//27-->29
				    "% Com Ger"		,;			//28-->30
					"Vlr Com Ger.Nac",;			//31
				    "% Com Ger.Nac"	 ,;			//32
				    "Sequenc.Comissão",;         //29-->35
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
			    	}		

   ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 // Não imprime Coordenador
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Gerente" 		,;			//21
				    "Nome ger."     ,;			//22
				    "Gerente Nac."  ,;			//23
				    "Nome ger.Nac"  ,;			//24
				    "Vlr Com Rep"	,;			//23-->25
				    "% Com Rep"		,;			//24-->26
				    "Vlr Com Sup"	  ,;    	//25-->27
				    "% Com Sup"		  ,;		//26-->28
				    "Vlr Com Ger"	  ,;		//27-->29
				    "% Com Ger"		  ,;		//28-->30
                    "Vlr Com Ger.Nac" ,;		//31
				    "% Com Ger.Nac"	  ,;	    //32
				    "Sequenc.Comissão",;         //29-->33
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	 }		
      
   ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 // Não imprime gerente
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
			 	    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Coordenador" 	,;			//21
				    "Nome cood."    ,;			//22
				    "Gerente Nac."  ,;			//23
				    "Nome ger.Nac"  ,;			//24
				    "Vlr Com Rep"	,;			//23-->25
				    "% Com Rep"		,;			//24-->26
				    "Vlr Com Sup"	,;			//25-->27
				    "% Com Sup"		,;			//26-->28
				    "Vlr Com Cood"	,;			//27-->29
				    "% Com Cood"	,;			//28-->30
                    "Vlr Com Ger.Nac",;			//31
				    "% Com Ger.Nac"	 ,;		    //32					
				    "Sequenc.Comissão",;         // 29-->33 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

   ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07// imprime apenas gerente nacional.
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Gerente Nac."  ,;			//17
				    "Nome ger.Nac"  ,;			//18
                    "Vlr Com Ger.Nac",;			//19
				    "% Com Ger.Nac"	 ,;		    //20
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

   ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas gerente
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Gerente" 		,;			//17
				    "Nome ger."     ,;			//18
				    "Vlr Com Ger"	,;			//19
				    "% Com Ger"		,;			//20
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

   ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 // imprime apenas Coordenador
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Coordenador" 	,;			//17
				    "Nome cood."    ,;			//18
				    "Vlr Com Cood"	,;			//19
				    "% Com Cood"	,;			//20
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
					  	
   ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 // imprime apenas supervisor
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Supervisor" 	,;			//17
				    "Nome sup."     ,;			//18
				    "Vlr Com Sup"	,;			//19
				    "% Com Sup"		,;			//20
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
					  	
   ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 // imprime apenas vendedor
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Vlr Com Rep"	,;			//19
				    "% Com Rep"		,;			//20
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: ROMS025D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 03/05/2019
Descrição-------: Monta o Cabeçalho do Relatório Baixa Detalhado. 
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS025D()

Begin Sequence
   //===========================================================================================
   //   TÍTULOS UTILIZADOS NOS RELATÓRIO BAIXA DETALHADO
   //===========================================================================================
   If Empty(MV_PAR07) .Or. ("G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07) // Imprime todos os dados  // 1 
	  _aTitulo := {	"Filial"		,;			//01
	       			"Tipo"			,;			//02
		    		"Dt. Emissão"	,;			//03
		 	    	"Dt. Baixa"		,;			//04
		 	    	"Documento"		,;			//05
			    	"Parcela"		,;			//06
			    	"Rede"			,;			//07
		    		"Desc Rede"		,;			//08
		   			"Cliente"		,;			//09
		   			"Loja"			,;			//10
		   			"Razão Social"	,;			//11
		   			"Valor Original",;			//12
		   			"Vlr Compensado",;			//13
		   			"Vlr Desconto"	,;			//14
		   			"Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Coordenador" 	,;			//21
				    "Nome cood."    ,;			//22
				    "Gerente" 		,;			//23
				    "Nome ger."     ,;			//24
					"Gerente Nacional",;		// 
				    "Nome ger.Nac." ,;			// 
				    "Vlr Com Rep"	,;			//25  sd1
				    "% Com Rep"		,;			//26  sd1
                    "% Com Nota Rep",;          // 27 A  Calculado.
					"Media % Sistemica Rep",;   // 28 A  Calculado.
				    "Vlr Com Sup"	,;			// 29 A // 27 B
				    "% Com Sup"		,;			// 30 A // 28 B
                    "% Com Nota Sup",;          // 31 A
					"Media % Sistemica Sup",;   // 32 A
				    "Vlr Com Cood"	,;			// 33 A // 29 B
				    "% Com Cood"	,;			// 34 A // 30 B
                    "% Com Nota Coord",;        // 35 A 
					"Media % Sistemica Coord",; // 36 A 
				    "Vlr Com Ger"	,;			// 37 A // 31 B
				    "% Com Ger"		,;			// 38 A // 32 B 
                     "% Com Nota Ger",;         // 40 A 
					"Media % Sistemica Ger",;   // 41 A 
					"Vlr Com Ger Nac"	,;		 // 
				    "% Com Ger Nac"		,;		 // 
                    "% Com Nota Ger Nac",;       // 
					"Media % Sistemica Ger Nac",;// 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				   }		
          
   ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07//  Não imprime vendedor  // 2
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
				    "Dt. Emissão"	,;			//03
				    "Dt. Baixa"		,;			//04
				    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Supervisor" 	,;			//17
				    "Nome sup."     ,;			//18
				    "Coordenador" 	,;			//19
				    "Nome cood."    ,;			//20
				    "Gerente" 		,;			//21
				    "Nome ger."     ,;			//22
					"Gerente Nacional",;		// 
                    "Nome ger.Nac." ,;		    // 
				    "Vlr Com Sup"	,;			//23
				    "% Com Sup"		,;			//24
                    "% Com Nota Sup",;          // 25 A
                    "Media % Sistemica Sup",;   // 26 A 
				    "Vlr Com Cood"	,;			// 27 A // 25 B
				    "% Com Cood"	,;			// 28 A // 26 B 
                    "% Com Nota Coord",;        // 29 A
                    "Media % Sistemica Coord",; // 30 A 
				    "Vlr Com Ger"	,;			// 31 A // 27 B
				    "% Com Ger"		,;			// 32 A // 28 B 
                    "% Com Nota Ger",;         // 33 A 
                    "Media % Sistemica Ger",;  // 34 A
					"Vlr Com Ger Nac"	,;		 // 
			        "% Com Ger Nac"		,;		 // 
                    "% Com Nota Ger Nac",;       // 
					"Media % Sistemica Ger Nac",;// 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
      
   ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime supervisor // 3
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 	     	"Dt. Emissão"	,;			//03
		 	    	"Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Coordenador" 	,;			//19
				    "Nome cood."    ,;			//20
				    "Gerente" 		,;			//21
				    "Nome ger."     ,;			//22
					"Gerente Nacional",;		// 
                    "Nome ger.Nac." ,;		    // 
				    "Vlr Com Rep"	,;			//23
				    "% Com Rep"		,;			//24
                    "% Com Nota Rep",;          // 25 A 
                    "Media % Sistemica Rep",;   // 26 A
				    "Vlr Com Cood"	,;			// 27 A // 25 B
				    "% Com Cood"	,;			// 28 A // 26 B
                    "% Com Nota Coord",;        // 29 A 
                    "Media % Sistemica Coord",; // 30 A 
				    "Vlr Com Ger"	,;			 // 31 A // 27 B
				    "% Com Ger"		,;			 // 32 A // 28 B
                    "% Com Nota Ger",;           // 33 A
                    "Media % Sistemica Ger",;    // 34 A
					"Vlr Com Ger Nac"	,;		 // 
			        "% Com Ger Nac"		,;		 // 
                    "% Com Nota Ger Nac",;       // 
					"Media % Sistemica Ger Nac",;// 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
			    	}		

   ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime Coordenador // 4
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Gerente" 		,;			//21
				    "Nome ger."     ,;			//22
					"Gerente Nacional",;		// 
                    "Nome ger.Nac." ,;		    // 
				    "Vlr Com Rep"	,;			//23
				    "% Com Rep"		,;			//24
                    "% Com Nota Rep",;          // 25 A
                    "Media % Sistemica Rep",;   // 26 A
				    "Vlr Com Sup"	,;			// 27 A // 25 B
				    "% Com Sup"		,;			// 27 A // 26 B
                    "% Com Nota Sup",;          // 28 A
                    "Media % Sistemica Sup",;   // 29 A 
				    "Vlr Com Ger"	,;			// 30 A // 27 B
				    "% Com Ger"		,;			// 31 A // 28 B
                    "% Com Nota Ger",;         // 32 A
                    "Media % Sistemica Ger",;  // 33 A
					"Vlr Com Ger Nac"	,;		 // 
	                "% Com Ger Nac"		,;		 // 
                    "% Com Nota Ger Nac",;       // 
					"Media % Sistemica Ger Nac",;// 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	 }		
      
   ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. "N" $ MV_PAR07 // Não imprime gerente  // 5
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
			 	    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Coordenador" 	,;			//21
				    "Nome cood."    ,;			//22
					"Gerente Nacional",;		// 
                    "Nome ger.Nac." ,;		    // 
				    "Vlr Com Rep"	,;			//23
				    "% Com Rep"		,;			//24
                    "% Com Nota Rep",;          // 25 A
                    "Media % Sistemica Rep",;   // 26 A
				    "Vlr Com Sup"	,;			// 27 A // 25 B
				    "% Com Sup"		,;			// 28 A // 26 B
                    "% Com Nota Sup",;          // 29 A
                    "Media % Sistemica Sup",;   // 30 A
				    "Vlr Com Cood"	,;			// 31 A // 27 B
				    "% Com Cood"	,;			// 32 A // 28 B
                    "% Com Nota Coord",;        // 33 A 
                    "Media % Sistemica Coord",; // 34 A 
					"Vlr Com Ger Nac"	,;		 // 
			        "% Com Ger Nac"		,;		 // 
                    "% Com Nota Ger Nac",;       // 
					"Media % Sistemica Ger Nac",; // 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

 ElseIf "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // Não imprime gerente nacional
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
			 	    "Supervisor" 	,;			//19
				    "Nome sup."     ,;			//20
				    "Coordenador" 	,;			//21
				    "Nome cood."    ,;			//22
					"Gerente"       ,;	    	// 
                    "Nome ger."     ,;		    // 
				    "Vlr Com Rep"	,;			//23
				    "% Com Rep"		,;			//24
                    "% Com Nota Rep",;          // 25 A
                    "Media % Sistemica Rep",;   // 26 A
				    "Vlr Com Sup"	,;			// 27 A // 25 B
				    "% Com Sup"		,;			// 28 A // 26 B
                    "% Com Nota Sup",;          // 29 A
                    "Media % Sistemica Sup",;   // 30 A
				    "Vlr Com Cood"	,;			// 31 A // 27 B
				    "% Com Cood"	,;			// 32 A // 28 B
                    "% Com Nota Coord",;        // 33 A 
                    "Media % Sistemica Coord",; // 34 A 
					"Vlr Com Ger"	,;		    // 
			        "% Com Ger"		,;		    // 
                    "% Com Nota Ger",;          // 
					"Media % Sistemica Ger",;   // 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

   ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. "N" $ MV_PAR07// imprime apenas gerente nacional
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Gerente Nacional",;		//17
				    "Nome Ger.Nac." ,;			//18
				    "Vlr Com Ger Nac"	,;		 //19
				    "% Com Ger Nac"		,;		 //20
                    "% Com Nota Ger Nac",;       // 21 A 
                    "Media % Sistemica Ger Nac",;// 22 A
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

   ElseIf "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas gerente  // 6
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Gerente" 		,;			//17
				    "Nome ger."     ,;			//18
				    "Vlr Com Ger"	,;			//19
				    "% Com Ger"		,;			//20
                    "% Com Nota Ger",;          // 21 A 
                    "Media % Sistemica Ger",;   // 22 A
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		

   ElseIf ! "G" $ MV_PAR07 .And. "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas Coordenador  // 7 
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Coordenador" 	,;			//17
				    "Nome cood."    ,;			//18
				    "Vlr Com Cood"	,;			//19
				    "% Com Cood"	,;			//20
                    "% Com Nota Coord",;        // 21 A
                    "Media % Sistemica Coord",; // 22 A 
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",; 
                "Vr ICM ST";
				  	}		
					  	
   ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. "S" $ MV_PAR07 .And. ! "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07// imprime apenas supervisor  // 8
       _aTitulo := {	"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Supervisor" 	,;			//17
				    "Nome sup."     ,;			//18
				    "Vlr Com Sup"	,;			//19
				    "% Com Sup"		,;			//20
                    "% Com Nota Sup",;          // 21 A
                    "Media % Sistemica Sup",;   // 22 A
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
					  	
   ElseIf ! "G" $ MV_PAR07 .And. ! "C" $ MV_PAR07 .And. ! "S" $ MV_PAR07 .And. "V" $ MV_PAR07 .And. ! "N" $ MV_PAR07 // imprime apenas vendedor  // 9
       _aTitulo := {"Filial"		,;			//01
				    "Tipo"			,;			//02
		 		    "Dt. Emissão"	,;			//03
		 		    "Dt. Baixa"		,;			//04
		 		    "Documento"		,;			//05
				    "Parcela"		,;			//06
				    "Rede"			,;			//07
				    "Desc Rede"		,;			//08
				    "Cliente"		,;			//09
				    "Loja"			,;			//10
				    "Razão Social"	,;			//11
				    "Valor Original",;			//12
				    "Vlr Compensado",;			//13
				    "Vlr Desconto"	,;			//14
				    "Vlr Baixas Ant",;			//15
				    "Base Comissão" ,;			//16
				    "Representante" ,;			//17
				    "Nome rep."     ,;			//18
				    "Vlr Com Rep"	 ,;			//19
				    "% Com Rep"		,;			//20
                    "% Com Nota Rep",;          // 21 A
                    "Media % Sistemica Rep",;   // 22 A
				    "Sequenc.Comissão",;         // 23 A // 21 B 
					"Val.Tit.Desc.",;			//"Vr Desconto",;
                "Vr Desc Contrato",;
                "Vr Desc Verba",;
                "Vr ICM ST";
				  	}		
	
   EndIf

   //===========================================================================================
   //   COMPLEMENTO DO TÍTULO DO RELATÓRIO BAIXA DETALHADO
   //===========================================================================================   
   //If MV_PAR08 == 2
      aAdd(_aTitulo,"Mix BI"      ) 
      aAdd(_aTitulo,"Item"        ) 
      aAdd(_aTitulo,"Produto"     )
      aAdd(_aTitulo,"Descrição"   )
      aAdd(_aTitulo,"Aliq.%"      )
      aAdd(_aTitulo,"Qtde"        )
      aAdd(_aTitulo,"U.M."        )
      aAdd(_aTitulo,"Qtde 2a U.M.")
      aAdd(_aTitulo,"2a U.M."     )
      aAdd(_aTitulo,"Vlr.Uni."    )
      aAdd(_aTitulo,"Valor Total" )
      aAdd(_aTitulo,"NF.Origem"   )
      aAdd(_aTitulo,"Serie Origem") 
      aAdd(_aTitulo,"Vr Desconto") 
      aAdd(_aTitulo,"Vr Desc Compensado") 
      aAdd(_aTitulo,"Vr Verba Descontado") 
      aAdd(_aTitulo,"Vr ICM ST") 
   //EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: ROMS025B
Autor-----------: Julio de Paula Paz
Data da Criacao-: 16/04/2019
Descrição-------: Retornar os valores dos percentuais de comissões gravados na tabela SD2.
Parametros------: _cFilialNF = Codigo da filial
                  _cNRNF     = Nr da nota fiscal
                  _cSerieNf  = Serie da nota fiscal
                  _cCodCli   = Codigo do cliente
                  _cLojaCli  = Loja do cliente
                  _cProd     = Codigo do produto
Retorno---------: _aRet = {Comissão 1, Comissão 2, Comissão 3, Comissao 4, Valor Total SF2, Valor Total Item, Comissão 5}
===============================================================================================================================
*/
User Function ROMS025B(_cFilialNF As Character,_cNRNF As Character,_cSerieNf As Character,_cCodCli As Character,_cLojaCli As Character,_cProd As Character) As Array
Local _aRet As Array
Local _aOrd As Array
Local _nRegSD2 As Numeric
Local _nRegSF2 As Numeric
Local _nVTotSF2 As Numeric

_aRet     := {}
_aOrd     := SaveOrd({"SD2","SF2"})
_nRegSD2  := SD2->(Recno())
_nRegSF2  := SF2->(Recno())
_nVTotSF2 := 0

Begin Sequence
   _aRet := {0,0,0,0, _nVTotSF2,0 }
   
   SF2->(DBSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
   If SF2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
      _nVTotSF2 := SF2->F2_VALMERC
   EndIf
   
   SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
   If SD2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
      While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")
         If SD2->D2_COD == U_ItKey(_cProd,"D2_COD")
            _aRet := {SD2->D2_COMIS1, SD2->D2_COMIS2, SD2->D2_COMIS3, SD2->D2_COMIS4, _nVTotSF2, SD2->D2_TOTAL, SD2->D2_COMIS5}
         EndIf   
         
         SD2->(DBSkip())   
      EndDo
   EndIf      
     
End Sequence

RestOrd(_aOrd)
SD2->(DBGoTo(_nRegSD2))
SF2->(DBGoTo(_nRegSF2))

Return _aRet

/*
===============================================================================================================================
Programa--------: ROMS025P
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/03/2019
Descrição-------: Função que Processa a impressão dos dados do relatório - Previsão de Comissão
Parametros------: _cFilialNF = Filial
                  _cCodCli   = Codigo do Cliente
				  _cLojaCli  = Loja do Cliente
				  _cPrefixo  = Prefixo
				  _cNRNF     = Numero NF
Retorno---------: _aParcelas = {{Nr Parcela, Percentual Parcela},{Nr Parcela, Percentual Parcela},...}
===============================================================================================================================
*/   
Static Function ROMS025P(_cFilialNF As Character, _cCodCli As Character, _cLojaCli As Character, _cPrefixo As Character, _cNRNF As Character) As Array
Local _aParcelas As Array
Local _aOrd As Array
Local _nRegAtu As Numeric
Local _nTotParc As Numeric
Local _aTitulosSE1 As Array
Local _nI As Numeric

_aParcelas := {}
_aOrd := SaveOrd({"SE1"})
_nRegAtu := SE1->(Recno())
_nTotParc := 0
_aTitulosSE1 := {}
_nI := 0

Begin Sequence
   SE1->(DBSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO 

   If SE1->(DBSeek(U_ItKey(_cFilialNF,"E1_FILIAL")+U_ItKey(_cCodCli,"E1_CLIENTE")+U_ItKey(_cLojaCli,"E1_LOJA")+U_ItKey(_cPrefixo,"E1_PREFIXO")+U_ItKey(_cNRNF,"E1_NUM")  ))
      
	  _aParcelas   := {}
      _nTotParc    := 0
      _aTitulosSE1 := {}

      While ! SE1->(Eof()) .And. SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM) == U_ItKey(_cFilialNF,"E1_FILIAL")+U_ItKey(_cCodCli,"E1_CLIENTE")+U_ItKey(_cLojaCli,"E1_LOJA")+U_ItKey(_cPrefixo,"E1_PREFIXO")+U_ItKey(_cNRNF,"E1_NUM")
         If AllTrim(SE1->E1_TIPO) == "NF"
		    If SE1->E1_SALDO > 0    //   1               2             3             4               5              6              7
			   aAdd(_aTitulosSE1,{SE1->E1_PARCELA, SE1->E1_SALDO,SE1->E1_COMIS1,SE1->E1_COMIS2,SE1->E1_COMIS3,SE1->E1_COMIS4, SE1->E1_VALOR})
			EndIf

            _nTotParc += SE1->E1_SALDO
         EndIf
               
         SE1->(DBSkip())
      EndDo
   EndIf

   For _nI := 1 To Len(_aTitulosSE1)
       aAdd(_aParcelas, {_aTitulosSE1[_nI,1],;   // Nr. da Parcela      1
 	                     _aTitulosSE1[_nI,2] / _nTotParc,; // % da Parcela   2
						 _aTitulosSE1[_nI,3],;   // % Comis1  3
						 _aTitulosSE1[_nI,4],;   // % Comis2  4
						 _aTitulosSE1[_nI,5],;   // % Comis3  5
						 _aTitulosSE1[_nI,6],;   // % Comis4  6
						 _aTitulosSE1[_nI,7],;   // Valor do Título  7
						 _aTitulosSE1[_nI,2]})   // Saldo do Título  8
   Next

   If Empty(_aParcelas) //  1     2  3  4  5  6  7   8
      aAdd(_aParcelas, {Space(2), 1, 1, 1, 1 ,1 ,1 , 1})
   EndIf

End Sequence

RestOrd(_aOrd)
SE1->(DBGoTo(_nRegAtu))

Return _aParcelas


/*
===============================================================================================================================
Programa--------: ROMS025R
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/03/2019
Descrição-------: Função que Processa a impressão dos dados do relatório - Previsão de Comissão
Parametros------: _cParcela     = Numero da Parcela
                  _nBaseComiss  = Valor base de Comissão
                  _nPercParcela = Percentual da Parcela  
                  _cFilialNF    = Filial
                  _cCodCli      = Codigo do Cliente
				  _cLojaCli     = Loja do Cliente
				  _cPrefixo     = Prefixo
				  _cNRNF        = Numero NF
Retorno---------: _aRet = {Nr Parcela, Comissão 1, Percentual 1, Comissão 2, Percentual 2, Comissão 3, Percentual 3, 
                           Comissão 4, Percentual 4, Comissão 4, Percentual 4}
===============================================================================================================================
*/   
Static Function ROMS025R(_cParcela As Character, _nBaseComiss As Numeric, _nPercParcela As Numeric ,_cFilialNF As Character, _cCodCli As Character, _cLojaCli As Character, _cPrefixo As Character, _cNRNF As Character) As Array
Local _aRet As Array
Local _aOrd As Array
Local _nRegAtu As Numeric
Local _nValBaseCom As Numeric
Local _nValCom1 As Numeric
Local _nValCom2 As Numeric
Local _nValCom3 As Numeric
Local _nValCom4 As Numeric
Local _nValCom5 As Numeric
Local _nPerCom1 As Numeric
Local _nPerCom2 As Numeric
Local _nPerCom3 As Numeric
Local _nPerCom4 As Numeric
Local _nPerCom5 As Numeric
Local _nTotalBase As Numeric

_aRet := {}
_aOrd := SaveOrd({"SD2"})
_nRegAtu := SD2->(Recno())
_nValBaseCom := 0
_nValCom1 := 0
_nValCom2 := 0
_nValCom3 := 0
_nValCom4 := 0
_nValCom5 := 0
_nPerCom1 := 0
_nPerCom2 := 0
_nPerCom3 := 0
_nPerCom4 := 0
_nPerCom5 := 0
_nTotalBase := 0

Begin Sequence
   _aRet = {_cParcela, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

   _nValBaseCom := _nBaseComiss 
   If _nValBaseCom == 0
      Break
   EndIf 
   
   _nValCom1 := 0
   _nValCom2 := 0
   _nValCom3 := 0
   _nValCom4 := 0
   _nValCom5 := 0
   _nTotalBase := 0

   SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM   
   SD2->(DBSeek(_cFilialNF+_cNRNF+_cPrefixo+_cCodCli+_cLojaCli))
   While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == _cFilialNF+_cNRNF+_cPrefixo+_cCodCli+_cLojaCli
      _nValCom1 += ((SD2->D2_COMIS1 / 100) * _nValBaseCom) 
      _nValCom2 += ((SD2->D2_COMIS2 / 100) * _nValBaseCom) 
      _nValCom3 += ((SD2->D2_COMIS3 / 100) * _nValBaseCom) 
      _nValCom4 += ((SD2->D2_COMIS4 / 100) * _nValBaseCom) 
      _nValCom5 += ((SD2->D2_COMIS5 / 100) * _nValBaseCom) 

      _nTotalBase += _nValBaseCom

      SD2->(DBSkip())
   EndDo

   _nPerCom1 := _nValCom1 / _nTotalBase //_nValBaseCom
   _nPerCom2 := _nValCom2 / _nTotalBase //_nValBaseCom
   _nPerCom3 := _nValCom3 / _nTotalBase //_nValBaseCom
   _nPerCom4 := _nValCom4 / _nTotalBase //_nValBaseCom
   _nPerCom5 := _nValCom5 / _nTotalBase //_nValBaseCom 

   _nValCom1 := (_nPerCom1 * _nValBaseCom) 
   _nValCom2 := (_nPerCom2 * _nValBaseCom) 
   _nValCom3 := (_nPerCom3 * _nValBaseCom) 
   _nValCom4 := (_nPerCom4 * _nValBaseCom) 
   _nValCom5 := (_nPerCom5 * _nValBaseCom) 

   _nPerCom1 := _nPerCom1 * 100
   _nPerCom2 := _nPerCom2 * 100
   _nPerCom3 := _nPerCom3 * 100 
   _nPerCom4 := _nPerCom4 * 100
   _nPerCom5 := _nPerCom5 * 100 

          //    1          2          3          4          5          6          7          8           9         10         11
   _aRet = {_cParcela, _nValCom1, _nPerCom1, _nValCom2, _nPerCom2, _nValCom3, _nPerCom3, _nValCom4, _nPerCom4, _nValCom5, _nPerCom5}

End Sequence

RestOrd(_aOrd)
SD2->(DBGoTo(_nRegAtu))

Return _aRet  

/*
===============================================================================================================================
Programa--------: U_ROMS025I
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/11/2019
Descrição-------: Retorna valores numéricos passados por parâmentro formatado ou não.
Parametros------: _nValorDado = Valor do dado numérico passado por parâmetro.
                  _cPicture   = Picture de formatação.
                  _lFormataN  = Formata Numero.
Retorno---------: _xRet = valor numerico sem formatação, ou
                        = valor alfanumérico sem formatação.                                             
===============================================================================================================================
*/
User Function ROMS025I(_nValorDado As Numeric,_cPicture As Character,_lFormataN As Logical) As Character
Local _xRet As Numeric

_xRet := 0

Default _lFormataN := .F. 
Default _cPicture  := "@E 999,999,999.99"

Begin Sequence
   If _lFormataN
      _xRet := Transform(_nValorDado,_cPicture)
   Else
      _xRet := _nValorDado
   EndIf

End Sequence

Return _xRet
