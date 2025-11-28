/*  
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO                             
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Walaluer | 26/11/2018 | Criação do RDMAKE. Chamado 27120
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"

/*
===============================================================================================================================
Programa--------: MOMS040
Autor-----------: Alex Wallauer
Data da Criacao-: 23/10/2018
===============================================================================================================================
Descrição-------: Acerta o valor do frete da Carga quando já gerou NF
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOMS040()
Local cTimeInicial:=Time()
Local _aParRet :={}
Local _aParAux :={} , nI 
Local _bOK     :={|| If(MV_PAR02 > 0 .And. !Empty(MV_PAR02),.T.,(U_ITMsg("Dados INVALIDO",'Atenção!',"Tente novamente com os dados corretos",3),.F.) ) }
Private aLogFre := {}

MV_PAR01:=Space(Len(DAK->DAK_COD))
MV_PAR02:=0
MV_PAR03:=1
//1  , 2                   , 3       , 4                        ,5      ,6         ,7    ,8    ,9
aAdd( _aParAux , { 1 , "Carga"	           , MV_PAR01, "@!" 	                , ""	, "DAK"		, "" , 080 , .F. } )
aAdd( _aParAux , { 1 , "Valor Frete"       , MV_PAR02, "@E 999,999,999,999.99"	, ""	, ""		, "" , 080 , .F. } )
aAdd( _aParAux , { 3 , "Tipo Processamento", MV_PAR03, {"Analise","Efetivar"}   , 40	, ""		, .T., .T. , .T. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.
	
	If !ParamBox( _aParAux , "Dados do frete da Carga" , @_aParRet, _bOK )
		Return .F.
	EndIf
	cTimeInicial:=Time()
	DBSelectArea("DAK")
	DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
	If DAK->( DBSeek( xFilial("DAK") + MV_PAR01 ) )
	   
		If 	U_ITMsg("Valor atual R$"+Str(DAK->DAK_I_FRET,15,2),'Atenção!',"Confirma a ateração do valor atual para o valor: R$"+Str(MV_PAR02,15,2) ,2,2,2)
			
			FWMsgRun( ,{|oProc|  fAtuaFrete(oProc,MV_PAR02,MV_PAR01) } , "Hora Inicial: "+cTimeInicial )
			
			If Len(aLogFre) > 0
				U_ITListBox( 'Log de Atualizao do FRETE da Carga (MOMS040)' ,;
				{'Carga','Pedido','Nf + Serie','Item','Frete / Ratiado',"Peso Rateio"},aLogFre,.F.,,,,;
				{     40,      35,          30,   30 ,     50          ,          50} )
			Else
				U_ITMsg("Não houve atualização para essa carga Carga",'Atenção!',"Tente novamente com os dados corretos",3)
				Loop
			EndIf
			
		Else
			Loop
		EndIf
		
	Else
		
		U_ITMsg("Carga não existe nesssa Filial: "+xFilial("DAK"),'Atenção!',"Tente novamente com os dados corretos",3)
		Loop
		
	EndIf
	
	Exit
	
EndDo


Return

/*
===============================================================================================================================
Programa--------: fAtuaFrete
Autor-----------: Alex Wallauer
Data da Criacao-: 26/11/2018
===============================================================================================================================
Descrição-------: Funcao para gravação do novo valor do Frete
===============================================================================================================================
Parametros------: oProc   , _nValor , _cCarga
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================*/
Static Function fAtuaFrete(oProc,_nValor , _cCarga )
Local _nPesoTot		:= 0
Local _nPesoTAux	:= 0
Local _nFretDAI 	:= 0

//================================================================================
//| Gravacao dao Valor total da Carga                                            |
//================================================================================
If oProc <> NIL
   oProc:cCaption :=  'Gravando Frete na Carga...'
   ProcessMessages()
EndIf

BEGIN TRANSACTION	

DBSelectArea("DAK")
DAK->( DBSetOrder(1) ) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
If DAK->( DBSeek( xFilial("DAK") + _cCarga ) )


	If MV_PAR03 = 2
	   DAK->( RecLock( "DAK" , .F. ) )
	   DAK->DAK_I_FRET := _nValor
	   DAK->( MSUnLock() )
	 EndIf
	//================================================================================
	//| Recupera o peso total da carga sem considerar Produtos Unitizadores do PALLET|
	//================================================================================
	_nPesoTot := U_CalPesCarg( _cCarga , 1 )
	
	//================================================================================
	//| Tratativa se somente foram encontrados produtos PALLET na montagem de carga  |
	//================================================================================
	If _nPesoTot == 0 
		_nPesoTAux := DAK->DAK_PESO
	EndIf
//                  'Carga'       ,'PV','Nf + Serie','Item','Frete',PESO
	aAdd(aLogFre, {_cCarga+" DAK:","","","",_nValor,_nPesoTot+_nPesoTAux} ) 
	
EndIf

//================================================================================
//| Grava Valor Rateado por item da Carga desconsiderando Produtos Unitizadores  |
//================================================================================
DBSelectArea("DAI")
DAI->( DBSetOrder(1) ) //DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
If DAI->( DBSeek( xFilial("DAI") + _cCarga ) )

   While DAI->(!Eof()) .And. DAI->DAI_COD == _cCarga .And. DAI->DAI_FILIAL == xFilial("DAI")
	
	    //================================================================================
	    //| Caso a carga possua Produtos acabados mais pedidos de PALLET sera rateado o  |
	    //| frete somente por Pedidos que nao sejam de PALLET                            |
	    //================================================================================
	    _nFretDAI:=0
		_cTipoPV:=""
		
	    If _nPesoTot > 0    
	    
			If U_CalPesCarg(DAI->DAI_PEDIDO,2) > 0
				
				_nFretDAI	:=	((_nValor /	_nPesoTot)	*	DAI->DAI_PESO)	       
			
			Else
				_cTipoPV:=" [P]"
			EndIf
		
		//================================================================================
        //| Caso a montagem de carga somene possua pedidos de PALLET                     |
        //================================================================================
		Else
		
			_cTipoPV:=" [P]"
			_nFretDAI	:=	( ( _nValor / _nPesoTAux ) * DAI->DAI_PESO )
			
		EndIf

	    If MV_PAR03 = 2 .And. _nFretDAI > 0
	       DAI->( RecLock( "DAI" , .F. ) )
		   DAI->DAI_I_FRET:=_nFretDAI
		   DAI->( MSUnLock() )
		EndIf

                    //'Carga'        ,'Pedido'                ,'Nf + Serie','Item','Frete'           ,PESO
        aAdd(aLogFre,{_cCarga+" DAI:",DAI->DAI_PEDIDO+_cTipoPV,""          ,""    ,Round(_nFretDAI,2),DAI->DAI_PESO})
		
	    DAI->( DBSkip() )
	    
	EndDo
	
EndIf

If oProc <> NIL
   oProc:cCaption :=  'Gravando Frete na NF...'
   ProcessMessages()
EndIf

If _nValor > 0 .And. DAK->DAK_PESO > 0

   DBSelectArea("SF2")
   SF2->( DBSetOrder(5) ) //F2_FILIAL+F2_CARGA+F2_SEQCAR+F2_SERIE+F2_DOC+F2_CLIENTE+F2_LOJA
   If SF2->(DBSeek( xFilial("SF2") + _cCarga ) )

      While SF2->(!Eof()) .And. SF2->F2_CARGA == _cCarga .And. SF2->F2_FILIAL == xFilial("SF2")

         GravaFrNF( _nValor , _nPesoTot , DAK->DAK_PESO,_cCarga )

	     SF2->( DBSkip() )
	    
       EndDo
   EndIf

   SF2->( DBSetOrder(1) )
   
EndIf

END TRANSACTION 	

Return


/*
===============================================================================================================================
Programa----------: GravaFrete
Autor-------------: Tiago Correa
Data da Criacao---: 08/02/2009
===============================================================================================================================
Descrição---------: Processa a gravação do valor do frete
===============================================================================================================================
Parametros--------: _nVlrTotFret , _nPesoTotC , _nPesoTAux ,_cCarga
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function GravaFrNF( _nVlrTotFret , _nPesoTotC , _nPesoTAux ,_cCarga )

Local _nVlrFretNF	:=	0
Local _cDoc			:= SF2->F2_DOC
Local _cSerie		:= SF2->F2_SERIE
Local _cCliente		:= SF2->F2_CLIENTE
Local _cLoja		:= SF2->F2_LOJA
Local _nPesoNota	:= SF2->F2_PBRUTO

//================================================================================
//| Se a carga possuir pedidos de PALLET e de outros produtos acabados as  notas |
//| de PALLET nao terao valor de FRETE rateado                                   | 
//================================================================================
If _nPesoTotC > 0
	
	If U_CalPesCarg( SF2->F2_I_PEDID , 2 ) > 0
		
		//Gravacao do Valor Frete por nota
		_nVlrFretNF := ( ( _nVlrTotFret / _nPesoTotC ) * _nPesoNota )

	    If MV_PAR03 = 2
		   SF2->( RecLock( "SF2" , .F. ) )
		   SF2->F2_I_FRET := _nVlrFretNF
		   SF2->( MSUnLock() )
		EndIf   
                    //'Carga'        ,'Pedido'       ,'Nf + Serie'             ,'Item','Frete'             ,PESO
        aAdd(aLogFre,{_cCarga+" SF2:",SF2->F2_I_PEDID,SF2->F2_DOC+SF2->F2_SERIE,""    ,Round(_nVlrFretNF,2),_nPesoNota})
		
		
		SD2->( DBSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		If SD2->( DBSeek( xFilial("SD2") + _cDoc + _cSerie + _cCliente + _cLoja ) )
			
			While SD2->(!Eof()) .And. SD2->( D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA ) == xFilial("SD2") + _cDoc + _cSerie + _cCliente + _cLoja
				
				_nPesoItem := ( Posicione( "SB1" , 1 , xFilial("SB1") + SD2->D2_COD , "B1_PESBRU" ) * SD2->D2_QUANT )
				
				//Gravacao do Valor Frete por item da Nota
	            If MV_PAR03 = 2
				   SD2->( RecLock( "SD2" , .F. ) )
				   SD2->D2_I_FRET := ( ( _nVlrFretNF / _nPesoNota ) * _nPesoItem )
				   SD2->( MSUnLock() )
				EndIf   
                            //'Carga'        ,'Pedido'       ,'Nf + Serie'             ,'Item'      ,'Frete'                                      ,PESO
                aAdd(aLogFre,{_cCarga+" SD2:",SF2->F2_I_PEDID,SF2->F2_DOC+SF2->F2_SERIE,SD2->D2_ITEM,Round(( _nVlrFretNF / _nPesoNota ) * _nPesoItem,2),_nPesoItem})
				
			SD2->( DBSkip() )
			EndDo
			
		EndIf
	Else            //'Carga'        ,'Pedido'              ,'Nf + Serie'             ,'Item','Frete',PESO
        aAdd(aLogFre,{_cCarga+" SD2:",SF2->F2_I_PEDID+" [P]",SF2->F2_DOC+SF2->F2_SERIE,""    ,0      ,_nPesoNota})
	EndIf

Else//Quando somente pedidos de PALLET compõem a carga
	
	//Gravacao do Valor do Frete por nota
	_nVlrFretNF := ( ( _nVlrTotFret / _nPesoTAux) * _nPesoNota )

    If MV_PAR03 = 2
	   SF2->( RecLock( "SF2" , .F. ) )
	   SF2->F2_I_FRET := _nVlrFretNF
	   SF2->( MSUnLock() )
	EndIf   
                //'Carga'        ,'Pedido'       ,'Nf + Serie'             ,'Item','Frete'    ,PESO
    aAdd(aLogFre,{_cCarga+" SF2:",SF2->F2_I_PEDID,SF2->F2_DOC+SF2->F2_SERIE,""    ,Round(_nVlrFretNF,2),_nPesoNota})
	
	SD2->( DBSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	If SD2->( DBSeek( xFilial("SD2") + _cDoc + _cSerie + _cCliente + _cLoja ) )
		
		While SD2->(!Eof()) .And. SD2->( D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA ) == xFilial("SD2") + _cDoc + _cSerie + _cCliente + _cLoja
			
			_nPesoItem := ( Posicione( "SB1" , 1 , xFilial("SB1") + SD2->D2_COD , "B1_PESBRU" ) * SD2->D2_QUANT )
			
			//Gravacao do Valor Frete por item da Nota                                     |
	        If MV_PAR03 = 2
			   SD2->( RecLock( "SD2" , .F. ) )
			   SD2->D2_I_FRET := ( ( _nVlrFretNF / _nPesoNota ) * _nPesoItem )
			   SD2->( MSUnLock() )
			EndIf   
			
                        //'Carga'        ,'Pedido'              ,'Nf + Serie'             ,'Item'      ,'Frete'                                      ,PESO
            aAdd(aLogFre,{_cCarga+" SD2:",SF2->F2_I_PEDID+" [P]",SF2->F2_DOC+SF2->F2_SERIE,SD2->D2_ITEM,Round(( _nVlrFretNF / _nPesoNota ) * _nPesoItem,2),_nPesoItem})
		    SD2->( DBSkip() )
		EndDo
		
	EndIf
	
EndIf

SD2->( DBSetOrder(1) )

Return
