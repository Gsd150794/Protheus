/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |17/07/2017| Chamado 20777. Virada de versão da P11 para a versão P12. Ajustes no fonte para a versão P12.
Alex Wallauer |31/10/2018| Chamado 26721. Alterações  para aceitar moeda diferente de Real
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120GET
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/07/2017
Descrição---------: Ponto de entrada de ajuste de coordenadas da tela de Pedido de Compras.
					Localização: Function A120PEDIDO - Função do Pedido de Compras responsavel pela inclusão, alteração, 
					exclusão e cópia dos PCs.
					Em que Ponto: Se encontra dentro da rotina que monta a dialog do pedido de compras antes  da montagem dos 
					gets da tela. É utilizado para alterar as coordenadas do array aPosObj para redimensionar a dialog.
Parametros--------: ParamIXB[1] - Array das coordenadas do objeto da dialog do Pedido de Compras
                    ParamIXB[2] - Opção selecionada no Pedido de Compras (inclusão, alteração, exclusão, etc.)
Retorno-----------: aPosObjPE = Objeto das coordenadas da dialog do Pedido de Compras
===============================================================================================================================
*/
User Function MT120GET

Local aPosObjPE	:= ParamIXB[1] As Array
Local _aCposRela  :={"C7_I_PRURS","C7_I_PRTRS"} As Array
Local _nX         := 0 As Numeric
Local _nI         := 0 As Numeric

aPosObjPE[2,1] := aPosObjPE[2,1] + 25
aPosObjPE[1,3] := aPosObjPE[1,3] + 21

If nMoedaPed = 1 
   For _nX := 1 To Len(_aCposRela)
      nPos:=aScan(aHeader,{|x| AllTrim(x[2]) == _aCposRela[_nX] })
      If nPos > 0
         aDel(aHeader,nPos)
         aSize(aHeader,Len(aHeader)-1)
         For _nI := 1 To Len(aCols)
            aDel(aCols[_nI],nPos)
            aSize(aCols[_nI],Len(aCols[_nI])-1)
         Next _nI
      EndIf
   Next _nX
EndIf

Return aPosObjPE
