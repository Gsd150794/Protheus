/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data     |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 09/08/2021 | Tratamento para o novo campo Z07_ORIGEM. Chamado 36432 
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: MOMS042
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/04/2019
===============================================================================================================================
Descrição---------: Altera planejamento logístico de pedidos de vendas - Chamado 28694 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS042()

//Valida se pedido não está  com nota emitida
If !Empty(SC5->C5_NOTA) 

    U_ITMsg("Pedido já foi faturado","Atenção",,1)
    Return

EndIf

//Valida se pedido não está  em carga
DAI->(DBSetOrder(4)) //DAI_FILIAL+DAI_PEDIDO
If DAI->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM)) 

    U_ITMsg("Pedido já está em carga","Atenção",,1)
    Return

EndIf

//Verifica permissão de ajuste de bloqueio logístico
ZZL->(DBSetOrder(3))
If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"

   	U_ITMsg("Usuário sem permissão para Definir Pedido em Planejamento Logístico","Atenção",,1)    	
    Return

EndIf

If SC5->C5_I_BLOG == "S" .And. U_ITMsg("Retirar Pedido do Planejamento Logístico " + SC5->C5_NUM + "?","Atenção",,2,2,2)

    U_MOMS042P("N")
    Return

EndIf

If SC5->C5_I_BLOG != "S" .And. U_ITMsg("Definir Pedido em Planejamento Logístico " + SC5->C5_NUM + "?","Atenção",,2,2,2)

    U_MOMS042P("S")
    Return

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS042P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/04/2019
===============================================================================================================================
Descrição---------: Grava flag de planejamento logístico
===============================================================================================================================
Parametros--------: _cgrv - string a gravar na flag
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS042P(_cgrv)

Local _nposi := SC5->(Recno())
Local _corig := SC5->C5_I_BLOG

BEGIN TRANSACTION

//Ajusta bloqueio no pedido posicionado
RecLock("SC5",.F.)
SC5->C5_I_BLOG := _cgrv
SC5->(MSUnLock())

//Grava o log do ajuste de bloqueio
If _corig != _cgrv

    MOMS042L(_corig)

EndIf

//Marca pedidos vinculados
If !Empty(SC5->C5_I_PEVIN)

    SC5->(DBSetOrder(1))
    If SC5->(DBSeek(xFilial("SC5")+SC5->C5_I_PEVIN))

        _corig := SC5->C5_I_BLOG

        RecLock("SC5",.F.)
        SC5->C5_I_BLOG := _cgrv
        SC5->(MSUnLock())

        //Grava o log do ajuste de bloqueio
        If _corig != _cgrv

            MOMS042L(_corig)

        EndIf

    EndIf

    SC5->(DBGoTo(_nposi))

EndIf

//Marca pedidos com vinculo de operação triangular
If !Empty(SC5->C5_I_PVREM) .And. SC5->C5_I_PVREM != SC5->C5_NUM

    SC5->(DBSetOrder(1))
    If SC5->(DBSeek(xFilial("SC5")+SC5->C5_I_PVREM))

        _corig := SC5->C5_I_BLOG

        RecLock("SC5",.F.)
        SC5->C5_I_BLOG := _cgrv
        SC5->(MSUnLock())

        //Grava o log do ajuste de bloqueio
        If _corig != _cgrv

            MOMS042L(_corig)

        EndIf

    EndIf

    SC5->(DBGoTo(_nposi))

EndIf

//Marca pedidos com vinculo de operação triangular
If !Empty(SC5->C5_I_PVFAT) .And. SC5->C5_I_PVFAT != SC5->C5_NUM

    SC5->(DBSetOrder(1))
    If SC5->(DBSeek(xFilial("SC5")+SC5->C5_I_PVFAT))

        RecLock("SC5",.F.)
        SC5->C5_I_BLOG := _cgrv
        SC5->(MSUnLock())
    EndIf

    SC5->(DBGoTo(_nposi))

EndIf

END TRANSACTION

Return

/*
===============================================================================================================================
Programa----------: MOMS042L
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/04/2019
===============================================================================================================================
Descrição---------: Grava log de ajuste de flag de planejamento logístico
===============================================================================================================================
Parametros--------: _corig - string original do pedido alterado
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS042L(_corig)

Z07->( RecLock( "Z07" , .T. ) )
						
Z07->Z07_FILIAL		:= xFilial("Z07")
Z07->Z07_ALIAS		:= 'SC5'
Z07->Z07_ORDEM		:= 1
Z07->Z07_CHAVE		:= SC5->C5_FILIAL+SC5->C5_NUM
Z07->Z07_OPCAO		:= 'B'
Z07->Z07_CAMPO		:= 'C5_I_BLOG'
Z07->Z07_CONORG		:= _corig
Z07->Z07_CONALT		:= SC5->C5_I_BLOG
Z07->Z07_CODUSU		:= RetCodUsr()
Z07->Z07_DATA		:= Date()
Z07->Z07_HORA		:= Time()
Z07->Z07_IFILIA		:= SC5->C5_FILIAL
Z07->Z07_INUM		:= SC5->C5_NUM
If Z07->(FIELDPOS("Z07_ORIGEM")) <> 0
   Z07->Z07_ORIGEM := "MOMS042"
EndIf
											
Z07->( MSUnLock() )

Return
