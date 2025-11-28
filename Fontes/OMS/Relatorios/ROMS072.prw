/*  
========================================================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
========================================================================================================================================================
    Autor    |    Data    |                                             Motivo                                           
--------------------------------------------------------------------------------------------------------------------------------------------------------
             |            | 
========================================================================================================================================================
*/
//===========================================================================
//| DefiniçõesIncludeludes                                                  |
//===========================================================================
#Include "TOTVS.ch"
 
/*
===============================================================================================================================
Programa----------: ROMS072
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/12/2022
===============================================================================================================================
Descrição---------: Lista Condições de Pagamento Personalizada para o cliente posicionado.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS072()
Local _aDados := {}
Local _aTitulos := {}

Begin Sequence 
   
   //_aTitulos := {"Condição Pagamento","Desc.Cond.Pagto","Item","Filial da Regra","Produto","Desc.Produto","Rede","Nome da Rede"}
   _aTitulos := {"Condição Pagamento","Desc.Cond.Pagto","Produto","Desc.Produto","Rede","Nome da Rede"}

   ZGO->(DBSetOrder(2)) // ZGO_CLIENT+ZGO_LOJA
   ZGO->(DBSeek(SA1->A1_COD+SA1->A1_LOJA))
   
   While ! ZGO->(Eof()) .And. ZGO->ZGO_CLIENT+ZGO->ZGO_LOJA == SA1->A1_COD+SA1->A1_LOJA
      
      aAdd(_aDados,{ZGO->ZGO_CONDPA,; // Condição Pagto  // SE4
                    Posicione("SE4",1,xFilial("SE4")+ZGO->ZGO_CONDPA,"E4_DESCRI"),;// ZGO->ZGO_CONDNI // Descrição Cond.Pagtp.  // virtual //ZGO->ZGO_ITEM,;   // Item  //ZGO->ZGO_FILCD,;  // Filial da regra
                    ZGO->ZGO_PRODUT,; // Produto
                    If(!Empty(ZGO->ZGO_PRODUT),Posicione("SB1",1,xFilial("SB1")+ZGO->ZGO_PRODUT,"B1_DESC"),""),;  //ZGO->ZGO_PRONOM // Descrição Produto 
                    ZGO->ZGO_REDE,;   // Rede 
                    If(!Empty(ZGO->ZGO_REDE),Posicione("ACY",1,xFilial("ACY")+ZGO->ZGO_REDE,"ACY_DESCRI"),"")}) // ZGO->ZGO_REDNOM // Nome da rede.         // virtual // If(!INCLUI,Posicione("ACY",1,xFilial("ACY")+ZGO->ZGO_REDE,"ACY_DESCRI")," ")
      
      ZGO->(DBSkip()) 
   EndDo 
   
   If Empty(_aDados)
      ZGO->(DBSetOrder(5)) // ZGO_REDE
      ZGO->(DBSeek(SA1->A1_GRPVEN))
   
      While ! ZGO->(Eof()) .And. ZGO->ZGO_REDE == SA1->A1_GRPVEN
      
         aAdd(_aDados,{ZGO->ZGO_CONDPA,; // Condição Pagto  // SE4
                       Posicione("SE4",1,xFilial("SE4")+ZGO->ZGO_CONDPA,"E4_DESCRI"),;// ZGO->ZGO_CONDNI // Descrição Cond.Pagtp.  // virtual //ZGO->ZGO_ITEM,;   // Item  //ZGO->ZGO_FILCD,;  // Filial da regra
                       ZGO->ZGO_PRODUT,; // Produto
                       If(!Empty(ZGO->ZGO_PRODUT),Posicione("SB1",1,xFilial("SB1")+ZGO->ZGO_PRODUT,"B1_DESC"),""),;  //ZGO->ZGO_PRONOM // Descrição Produto 
                       ZGO->ZGO_REDE,;   // Rede 
                       If(!Empty(ZGO->ZGO_REDE),Posicione("ACY",1,xFilial("ACY")+ZGO->ZGO_REDE,"ACY_DESCRI"),"")}) // ZGO->ZGO_REDNOM // Nome da rede.         // virtual // If(!INCLUI,Posicione("ACY",1,xFilial("ACY")+ZGO->ZGO_REDE,"ACY_DESCRI")," ")
      
         ZGO->(DBSkip()) 
      EndDo 
   EndIf

   If Empty(_aDados)
      aAdd(_aDados,{" ",; // Condição Pagto  // SE4
               " ",; // Desc.Cond.Pagto //" ",; // Item  " ",; // Filial da regra
               " ",; // Produto
               " ",; // Descrição Produto 
               " ",; // Rede 
               " "}) // Desc.Rede
   EndIf 

   U_ITListBox("Listagem de Condições de Pagamento Personalizada" , _aTitulos , _aDados , .T. , 1 , "Exportação excel/arquivo")

End Sequence 

Return 
