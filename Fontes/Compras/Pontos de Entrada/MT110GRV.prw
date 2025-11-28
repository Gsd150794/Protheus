/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
Alex Wallauer |22/10/2019| Chamado 30921. Tratamento para o campo NOVO CLAIM. 
Alex Wallauer |20/02/2024| Chamado 46303. Andre. Correção da limpeza dos Campos da indicação do Comprador.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110GRV
Autor-------------: Tiago Correa Castro
Data da Criacao---: 01/08/2008
Descrição---------: Ponto de Entrada apos a gravacao de cada item do SC1
					Localização: Function A110GRAVA - Função da Solicitação de Compras responsavel pela gravação das SCs.
					Em que Ponto: No laco de gravação dos itens da SC na função A110GRAVA, executado após gravar o item da SC, 
					a cada item gravado da SC o ponto é executado.
Parametros--------: ParamIXB -> L -> Caso ParamIXB == .T.(Cópia da solicitação de compras está ativa), se .F.(Cópia não está ativa)
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT110GRV

Local _aArea 		:= FWGetArea()
Local _lCopia		:= ParamIXB[1]

If Altera .And. !(SC1->(Eof()))

	SC1->( RecLock( 'SC1' , .F. ) )
        SC1->C1_I_CLAIM     := cClaim//CLAIM
		SC1->C1_I_APROV		:= ''
		SC1->C1_I_DTAPR		:= SToD('')
		SC1->C1_I_HRAPR		:= ''
		SC1->C1_I_CDSOL		:= __cUserId 
		SC1->C1_I_DTINC		:= Date()		
		SC1->C1_I_HRINC		:= Time()		
		SC1->C1_I_APLIC		:= cAplic
		SC1->C1_CC			:= cCCust
		SC1->C1_I_URGEN		:= cUrgen
		SC1->C1_I_CODAP		:= cAprov
		SC1->C1_I_CDINV		:= cCInve
		SC1->C1_APROV		:= "B"
		SC1->C1_I_SITWF		:= "1"
		SC1->C1_I_OBSSC		:= cObsSC
        //Campos da indicação do Comprador
		SC1->C1_CODCOMP		:= ""
		SC1->C1_GRUPCOM		:= ""
		SC1->C1_I_DTRET		:= SToD('')
		SC1->C1_I_INDIC     := ""
		SC1->C1_I_INDDT     := SToD('')
		SC1->C1_I_INDHR     := ""
	SC1->( MSUnLock() )

ElseIf Inclui

	SC1->( RecLock( 'SC1', .F. ) )
        SC1->C1_I_CLAIM     := cClaim//CLAIM
		SC1->C1_I_APROV		:= cAprov
		SC1->C1_I_DTAPR		:= SToD('')
		SC1->C1_I_HRAPR		:= ''
		SC1->C1_I_APLIC		:= cAplic
		SC1->C1_CC			:= cCCust
		SC1->C1_I_URGEN		:= cUrgen
		SC1->C1_I_CODAP		:= cAprov
		SC1->C1_I_CDINV		:= cCInve
		SC1->C1_I_CDSOL 	:= __cUserId
		SC1->C1_APROV		:= "B"
		SC1->C1_I_SITWF		:= "1"
		SC1->C1_I_OBSSC		:= cObsSC
        //Campos da indicação do Comprador
		SC1->C1_CODCOMP		:= ""
		SC1->C1_GRUPCOM		:= ""
		SC1->C1_I_DTRET		:= SToD('')
		SC1->C1_I_INDIC     := ""
		SC1->C1_I_INDDT     := SToD('')
		SC1->C1_I_INDHR     := ""
    SC1->( MSUnLock() )
	
ElseIf _lCopia .And. !(SC1->(Eof()))

	SC1->( RecLock( 'SC1', .F. ) )
        SC1->C1_I_CLAIM     := cClaim//CLAIM
		SC1->C1_I_APROV		:= cAprov
		SC1->C1_I_APLIC		:= cAplic
		SC1->C1_CC			:= cCCust
		SC1->C1_I_URGEN		:= cUrgen
		SC1->C1_I_CODAP		:= cAprov
		SC1->C1_I_CDINV		:= cCInve
		SC1->C1_I_CDSOL 	:= __cUserId
		SC1->C1_APROV		:= "B"
		SC1->C1_I_SITWF		:= "1"
		SC1->C1_I_OBSSC		:= cObsSC
		SC1->C1_I_HTM		:= Space(TamSX3("C1_I_HTM")[1])
		SC1->C1_I_WFID		:= Space(TamSX3("C1_I_WFID")[1])
		SC1->C1_I_OBSAP		:= Space(TamSX3("C1_I_OBSAP")[1])
		SC1->C1_I_DTAPR		:= SToD('')
		SC1->C1_I_HRAPR		:= Space(TamSX3("C1_I_HRAPR")[1])
		SC1->C1_I_USREL 	:= '' 
		SC1->C1_I_DTELR 	:= SToD('')
		SC1->C1_I_HRELR		:= ''
		SC1->C1_I_DTINC		:= Date()
		SC1->C1_I_HRINC		:= Time()
        //Campos da indicação do Comprador
		SC1->C1_CODCOMP		:= ""
		SC1->C1_GRUPCOM		:= ""
		SC1->C1_I_DTRET		:= SToD('')
		SC1->C1_I_INDIC     := ""
		SC1->C1_I_INDDT     := SToD('')
		SC1->C1_I_INDHR     := ""
	SC1->( MSUnLock() )

EndIf

FWRestArea(_aArea)

Return
