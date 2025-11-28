/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/06/2025| Chamado 45229. Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP")
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Julio Paz     |18/09/2025| Chamado 51806. Ajuste na condição para atualização do campo C5_I_ENVRD.
===============================================================================================================================
*/ 

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MTA410T
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 04/08/2011
Descrição-------: P.E. após o processamento da manutenção e liberação de pedidos de vendas
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MTA410T

Local _cFilHabilit := SuperGetMV('IT_FILINTW',.F.,'')
Local _laoms074 := .F.
Local _laoms112 := .F.
Local _nPerSegFob := SuperGetMV('IT_PERSEGF',.F.,0.013)
Local _lHabTpFFb  := .F. // HABILITADO TIPO FRETE FOB.
Local _nValTotImp  := 0
Local _nValSeguro  := 0
Local _cOperFret := SuperGetMV("IT_OPERFRE",.F.,"") 
Local _dDtCalcFr := Ctod(SuperGetMV("IT_DTCALCF",.F.,"23/06/2022"))

//Se veio do webservice já retorna .T.
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
	_laoms074 := .T.
EndIf

//Se esta sendo chamado via AOMS112/MOMS050 (Central Pedido Portal / Efetivaççao Automatica)
If FWIsInCallStack("U_AOMS112") .Or. FWIsInCallStack("U_MOMS050")
	_laoms112 := .T.
EndIf

If (FUNNAME()=='MATA410' .Or. FUNNAME()=='AOMS061' .Or. _laoms112 .Or. FWIsInCallStack("U_AOMS116")) .And. !_laoms074
	
	If  SC5->C5_I_ENVRD <> 'S' // SC5->C5_I_ENVRD == 'S' 
		
		SC5->( RecLock( "SC5", .F. ) )
		SC5->C5_I_ENVRD := "N" 
		SC5->( MSUnLock() )
		
		If SC5->C5_FILIAL $ _cFilHabilit // Filiais habilitadas na integracao Webservice Italac x RDC.
			U_AOMS084P()
		EndIf
	EndIf
  
	// Verifica e grava valor de seguro calculado sobre valor do pedido de vendas com impostos. 
 	_lHabTpFFb := Posicione('SA1',1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),'A1_I_FOB')
    
	If ValType(_lHabTpFFb) == "L" .And. _lHabTpFFb .And. SC5->C5_TPFRETE $ "F/D" .And. !(SC5->C5_I_OPER $ _cOperFret) .And. DToS(SC5->C5_EMISSAO) >= DToS(_dDtCalcFr) ;
	   .And. !(SC5->C5_CONDPAG == "001") // Não calcular o seguro se a condição de pagamento For 'a vista'.
       _nValTotImp := Ma410Impos( 6, .T., {}) // Total do Pedido de Vendas com impostos.
       _nValSeguro := _nValTotImp * _nPerSegFob / 100
       
	   SC5->( RecLock( "SC5", .F. ) )
	   SC5->C5_SEGURO := Round(_nValSeguro,2)
	   SC5->( MSUnLock() )
	Else
	   SC5->( RecLock( "SC5", .F. ) )
	   SC5->C5_SEGURO := 0
	   SC5->( MSUnLock() )
	EndIf 
EndIf 

If !_laoms074
	U_ENVSITPV() //Envia interface de situação do pedido para o RDC se For pedido RDC e grava campo de situação do pedido XFUNOMS
EndIf

// Chama a rotina de geração de pedidos de pallets de devolução.
If SC5->C5_I_GPADV == "S" .And. SC5->C5_I_PEDPA <> 'S'   
   U_AOMS147()
EndIf 

Return 
