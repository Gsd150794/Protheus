/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |17/01/2025| Chamado 48539. Recalcular e alterar as quantidades dos itens de pedidos de compras do tipo serviço
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Função-------------: ACOM041
Autor--------------: Julio de Paula Paz
Data da Criacao----: 16/09/2024
Descrição----------: Função de controle de inclusões de solicitações de compras e pedidos de compras que possuem 
                     produtos do tipo prestação de serviços.
                     Retorna conteúdo para os campos C1_I_SVPAR e C7_I_SVPAR.
Parametros---------: Nenhum
Retorno------------: _cRet = "S" = Sim, possui controle de entregas parciais.
                           = "N" = Não, não possui controle de entregas parciais.
===============================================================================================================================
*/  
User Function ACOM041

Local _cRet := "N"

Begin Sequence 
   
   If FWIsInCallStack("MATA110") // Chamada da Solicitação de Vendas

      _nPosProd  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C1_PRODUTO"}) 
      _cTipo   := Posicione("SB1",1,xFilial("SB1")+Acols[N,_nPosProd],"B1_TIPO") 
      
      If _cTipo == "SV"
         If U_ITMsg("Produto serviço: controlar entregas parciais?","Atenção" , , ,2, 2)
            _cRet := "S"
         EndIf 
      EndIf 
   Else // Chamada do Pedido de Vendas
      _nPosProd  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_PRODUTO"}) 
      _cTipo   := Posicione("SB1",1,xFilial("SB1")+Acols[N,_nPosProd],"B1_TIPO") 
      
      If _cTipo == "SV"
         If U_ITMsg("Produto serviço: controlar entregas parciais?","Atenção" , , ,2, 2)
            _cRet := "S"
         EndIf 
      EndIf 
   EndIf 

End Sequence

Return _cRet 

/*
===============================================================================================================================
Função-------------: ACOM041
Autor--------------: Julio de Paula Paz
Data da Criacao----: 16/09/2024
Descrição----------: Função de controle de inclusões de solicitações de compras e pedidos de compras que possuem 
                     produtos do tipo prestação de serviços.
                     Retorna conteúdo para os campos C1_I_SVPAR e C7_I_SVPAR.
Parametros---------: Nenhum
Retorno------------: _cRet = "S" = Sim, possui controle de entregas parciais.
                           = "N" = Não, não possui controle de entregas parciais.
===============================================================================================================================
*/  
User Function ACOM041P

Local _nI
Local _nPosProd
Local _cTipo  
Local _nPosCrlEn

Begin Sequence 
   
   SC1->(DBSetOrder(2)) // C1_FILIAL+C1_PRODUTO+C1_NUM+C1_ITEM+C1_FORNECE+C1_LOJA

   _nPosCrlEn  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_I_SVPAR"}) 
   _nPosItem   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_ITEM"}) 
   _nPosItSC   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_ITEMSC"}) 
   _nPosNrSC   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_NUMSC"}) 
   _nPosDesc   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_DESCRI"})
   _nPosQtd    := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_QUANT"})
   _nPosQtdSo  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_QTDSOL"})
   _nPosTotal  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_TOTAL"})
   _nPosPreco  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_PRECO"})
   _nPosProd   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="C7_PRODUTO"})  

   For _nI := 1 To Len(aCols)
   
       _cTipo      := Posicione("SB1",1,xFilial("SB1")+Acols[_nI,_nPosProd],"B1_TIPO") 
      
       If _cTipo == "SV"
          
          If U_ITMsg("Produto serviço: controlar entregas parciais?" + CRLF + ;
                     "Item: " + Acols[_nI,_nPosItem] + CRLF + ;
                     "Produto: " + AllTrim(Acols[_nI,_nPosProd]) + CRLF + ;
                     "Descrição: " + AllTrim(Acols[_nI,_nPosDesc]) ;
                     ,"Atenção" , , ,2, 2)

             //====================================================
             // Posicionar na SC1 para obtenção das Quantidades 
             //====================================================
             // Indice 2: C1_FILIAL+C1_PRODUTO+C1_NUM+C1_ITEM+C1_FORNECE+C1_LOJA
             SC1->(MsSeek(xFilial("SC1")+Acols[_nI,_nPosProd]+Acols[_nI,_nPosNrSC]+Acols[_nI,_nPosItSC]))
             
             //====================================================
             // Atualizar a SC7 com as quantidades da SC1 
             //====================================================
             Acols[_nI,_nPosCrlEn] := "S"
          EndIf 
       EndIf
       
   Next 

End Sequence 

Return
