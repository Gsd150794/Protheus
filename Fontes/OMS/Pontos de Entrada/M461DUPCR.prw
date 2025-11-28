/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |23/09/2025| Chamado 49221. Ajustes para compensação de títulos do SE1. 
Lucas Borges  |25/09/2025| Chamado 52262. Corrigido nome da variável
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M461DUPC
Autor-------------: Talita Teixeira
Data da Criacao---: 20/11/2014
Descrição---------: Ponto de Entrada ao gerar titulos de cédito para fornecedor no caso de nota fiscal de devolução de compras.
                    PE dentro da função ADupCred() dentro do progrma MATXATU.PRX 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M461DUPCR

Local _cDias   := "" As character
Local _aCond   := "" As array
Local _dData   := Stod('') As date
Local _dVencRea:= Stod('') As date
Local _dVenc   := Stod('') As date

SE4->(DBSetOrder(1))
If cArqSE = "SE2" .And. SE4->(MsSeek(FWxFilial("SE4")+SF2->F2_COND))//SF2 já vem posicionado
   _cDias:= AllTrim( SE4->E4_COND )
   _aCond:= StrtoKarr( _cDias , ',' )
   If (Len(_aCond) == 1 .Or. SE4->E4_TIPO == '7')
      If SE4->E4_TIPO == '7'
         _dData   := StoD( cValToChar( Year( Date() ) ) + StrZero( Month( Date() ) , 2 ) + AllTrim( _aCond[2] ) )
         _dVencRea:= DataValida( MonthSum( _dData , 1 ) )
      Else
         _dVenc   := Date() + Val( _cDias )
         _dVencRea:= DataValida( _dVenc )
      EndIf

      IF SE2->(!Eof())
         SE2->( RecLock( 'SE2' , .F. ) )
         SE2->E2_VENCTO := _dVenc
         SE2->E2_VENCREA:= _dVencRea
         SE2->( MSUnLock() )
      EndIf
   EndIf
EndIf

Return
