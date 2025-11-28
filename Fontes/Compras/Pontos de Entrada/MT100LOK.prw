/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |20/12/2019| Chamado 30971. Criar função para calcular CAT 42/2018 na digitação dos itens da nota de entrada.
Lucas Borges  |16/01/2020| Chamado 23984. Criada validação para não executar quando For chamado pelo TOTVS Colaboração.
Lucas Borges  |02/07/2020| Chamado 33422. Tratado para não ser executado quando chamado pelo Reprocessar.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT100LOK
Autor-------------: Tiago Correa Castro
Data da Criacao---: 09/01/2009
Descrição---------: Ponto de entrada na validacao da linha digitada no documento de entrada
					Localização : Function A119LinOk e A119TudOK - Função de Validação ( linha OK da Getdados) para Inclusão/
					Alteração do item da NF de Despesas de Importação e A103LinOk - Função de Validação da LinhaOk.
					Em que Ponto: No final das validações após a confirmação da inclusão ou alteração da linha, antes da 
					gravação da NF de Despesas de Importação.
					Finalidade: Permite alterar itens da NF de Despesas de Importação.
Parametros--------: ExpL1 -> L -> Sempre .T., indicando que as validações estão OK até este ponto.
Retorno-----------: .T. = Permite a confirmacao da digitacao da linha
------------------: .F. = Nao Permite a confirmacao da digitacao da linha
===============================================================================================================================
*/
User Function MT100LOK

Local _lRet   	:= .T.
Local _aArea	:= FWGetArea()
Local _cCodArmaz:=	aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "D1_LOCAL"	} )
Local _cCodPro	:=	aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "D1_COD"	} )
Local _lRLeite	:= !AllTrim( Upper( FUNNAME() ) ) $"U_MGLT009/MGLT010"

//Tratado para que o PE não seja executado indevidamente até a análise da TOTVS
If !FWIsInCallStack("SCHEDCOMCOL")
   //========================================================================================
   //Validação de usuário x filial x armazém
   //========================================================================================

   If _lRLeite .And. !aCols[n][Len(aHeader)+1] //Não verifica linhas deletadas
      
      //============================================
      //Valida armazémxprodutoxfilialxusuário
      //============================================
      _lRet := U_ACFG004E(AllTrim(RetCodUsr()), AllTrim(xFilial("SD1")), AllTrim(acols[n][_cCodArmaz]),AllTrim(acols[n][_ccodPro]),.T.)[1]
      
   EndIf

   If Inclui
      U_MT100CAT() 
   EndIf
EndIf

FWRestArea(_aArea)

Return( _lRet )             

/*
===============================================================================================================================
Programa----------: MT100CAT
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/12/2019
Descrição---------: Calcula o CAT 42/2018 dos itens no momento da digitação e lê as aliquotas/margens de cadastro.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT100CAT

Local _nPosTes                                     
Local _nPosBDes, _nPosIDes, _nPosADes
Local _nPosTot, _nPosVIcm
Local _cGrupoP

Begin Sequence            
   _nPosTes   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_TES"}) 
   //_nPosGrupo := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_GRUPO"})  
   _nPosProd  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_COD"}) 
   _nPosBDes  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_BASNDES"}) 
   _nPosIDes  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_ICMNDES"}) 
   _nPosADes  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_ALQNDES"}) 
   _nPosTot   := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_TOTAL"}) 
   _nPosVIcm  := aScan(aHeader,{|nx| Upper(AllTrim(nx[2]))=="D1_VALICM"}) 
       
   _cGrupoP   := Posicione("SB1",1,xFilial("SB1")+Acols[N,_nPosProd],"B1_GRUPO") 
   
   //=====================================================================================================
   // Atualiza campos da CAT 42/2018
   //===================================================================================================== 
   ZM2->(DBSetOrder(1)) // ZM2_FILIAL+ZM2_TES+ZM2_GRUPO

   If ZM2->(DBSeek(xFilial("ZM2")+Acols[N,_nPosTes]+_cGrupoP))   
      _nBasest := ZM2->ZM2_MARGEM 
      _nAliqn  := ZM2->ZM2_ALIQUO 

	  If _nBasest > 0
	     Acols[N,_nPosBDes] := Acols[N,_nPosTot] * _nBasest
	     Acols[N,_nPosIDes] := (Acols[N,_nPosTot] * _nBasest * (_naliqn/100)) - Acols[N,_nPosVIcm]
	     Acols[N,_nPosADes] := _nAliqn
      EndIf
   EndIf

End Sequence

Return
