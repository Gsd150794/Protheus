/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |01/06/2016| Chamado 15574. Adicionar a ordem de produção, código/ descrição do produto a ser produzido e exibir na tela
===============================================================================================================================
*/

#Include "TOTVS.ch"
                     
/*
===============================================================================================================================
Programa----------: MA381BUT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 27/10/2015
Descrição---------: Ponto de entrada para controlar menu de browse na tela de ajuste de empenhos - Chamado 12006
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MA381BUT()
Local _cOrdProd := cOP, _cNum, _cItem, _cSequen 
Local _aOrd := SaveOrd({"SC2"}) 

//adiciona o botão para tela de desmontagem do creme
Local _aBotoes := aClone(ParamIXB[2])

aAdd( _aBotoes, { "TELDES", { || U_EMP650(1) }, "Desm. Creme" } )

//====================================================================================================
// Adicionar a ordem de produção, o código e descrição do produto a ser produzido e exibir na tela.
//====================================================================================================
_cNum    := SubStr(_cOrdProd,1,6)
_cItem   := SubStr(_cOrdProd,7,2)
_cSequen := SubStr(_cOrdProd,9,3)

SC2->(DBSetOrder(1)) // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD

If SC2->(DBSeek(xFilial("SC2")+_cNum+_cItem+_cSequen))
   cOP := AllTrim(_cOrdProd)+Space(100)+"Produto: "+AllTrim(SC2->C2_PRODUTO)+" - "+SC2->C2_I_DESC
EndIf 

RestOrd(_aOrd,.T.)

Return _aBotoes
