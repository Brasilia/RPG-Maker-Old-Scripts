#==============================================================================#
# Lehanius Pathfinder
#------------------------------------------------------------------------------#
# Autor: Lehanius
#
# Versão: VXA 1.0 BR
# Data: d/m 23/01/2012
#
# Contatos:
# - http://www.santuariorpgmaker.com/forum/index.php?action=profile;u=80
# - rafael_1247@hotmail.com
#
#==============================================================================#
#
#==============================================================================#
# Descrição
#------------------------------------------------------------------------------#
#   Este sistema possibilita que o jogador, eventos ou seguidores se movam até
# um objetivo especificado, seja ele um personagem (jogador, evento ou seguidor)
# ou mesmo um ponto fixo do mapa, contornando qualquer obstáculo que esteja 
# entre eles, desde que seja contornável, claro.
#   * Este script depende do script Lehanius Eventer Tools para funcionar; ele
# pode ser encontrado no fórum da santuariorpgmaker em sua versão mais atual.
#==============================================================================#
#
#==============================================================================#
# Termos de Uso - Terms of Use
#------------------------------------------------------------------------------#
#   - IMPORTANTE:                                                      
#   * Este script pode ser utilizado livremente para projetos pessoais,
# porém peço os devidos créditos ao autor.
#   * Se modificado, este script não deve ser distribuído sem que se
# explicite que ele foi alterado.
#   * Não remova nem altere os comentários do cabeçalho deste script,
# mesmo se o código for alterado. Quando for esse o caso, indique a
# alteração abaixo destes comentários.
#   * Se encontrar algum bug, por favor me informe por um dos contatos acima.                                                        
#                                                                      
#   - NOTICE:                                                          
#   * This script may be used for private projects, though the author  
# should be credited properly.                                         
#   * If you wish to modify and distribute this script, please make    
#  sure to inform that it has been modified.                           
#   * Do not remove or change the contents of these header comments.   
# If you have modified the script, please state it below this header.  
#   * If you find any bugs, please contact me by email or by the forum.
#==============================================================================#

=begin
                                INSTRUÇÕES
                               
  Existem dois modos de funcionamento deste pathfinder:
  
    - mode 0: "ir para" - para ser usado em cenas, em direção a locais estáticos
      (que não se movem), pois o personagem fará o caminho completo até o 
      objetivo, sem poder ser interrompido;
      
    - mode 1: "ir para sem esperar" - funciona da mesma forma que o mode 0, 
      exceto pelo fato de que o movimento não precisa ser completado para que 
      se execute o próximo comando na lista do evento com o comando de script;
      
    - mode 2: "seguir" - para ser usado repetidamente, até mesmo em processos 
      paralelos, geralmente em direção a objetivos móveis, pois cada vez que 
      um comando neste modo é chamado, o personagem avança um passo em direção
      a seu objetivo, sem interromper as ações do jogador.
      
  
  Para usar o pathfinder, use um comando de chamar script assim:
  
    Script: pf = LET::PathFinder.new(<inteiro>)
          : pf.find_path(<objetivo>, <distância>, <modo>, <alcance>)
          
    Sendo que:
      - <inteiro> pode ser: 0 para o personagem; negativo para um seguidor que 
        ocupa a posição '-<inteiro>' na fila; positivo para a ID de um evento.
        Este será o personagem que irá andar até o objetivo especificado.
        
      - <objetivo> pode receber a mesma entrada que <inteiro> além de uma 
        entrada da classe LET::Point, que é um ponto com valores de x e y, que
        pode ser definido assim: ponto = LET::Point.new(<x><y>)
        
      - <distância> a distância que o personagem deve manter de seu objetivo;
        se for 0, ele irá pisar sobre o objetivo; se for maior que 0, manterá
        alguma distância de seu objetivo. Padrão: 0
        
      - <modo> 0, 1 ou 2, já explicado anteriormente. Padrão: 0
      
      - <alcance> número máximo de tiles a serem percorridos até o objetivo;
        se a distância for maior que o alcance, o personagem não irá tentar
        seguir o objetivo; o valor padrão desse parâmetro pode ser modificado 
        pela variável PF_DEFAULT_RANGE do módulo LET.
    
  Observações:
    - Note que as opções de passabilidade dos eventos (atravessar, por exemplo)
    determinarão quais tiles serão passáveis para eles;
    - Seguidores têm a passabilidade tratada como se fossem o jogador.
    
=end

#==============================================================================#
# Module LET
#------------------------------------------------------------------------------#
module LET
  PF_DEFAULT_RANGE = 40
  #============================================================================#
  # LET::PathFinder - para encontrar rotas
  #----------------------------------------------------------------------------#
  class PathFinder < Character
    def initialize(id)
      super(id)
    end
    #--------------------------------------------------------------------------
    # * Encontra o caminho para o local alvo: Game_Character ou LET::Point
    # target: identificador do personagem (negativo para seguidores, zero para o
    # jogador e positivo para eventos)
    # distance: distância que o personagem manterá de seu objetivo final
    # range: distância máxima da rota até o objetivo
    # mode: 0 - ir para; 1 - ir para sem esperar; 2 - seguir
    #--------------------------------------------------------------------------
    def find_path(target, distance = 0, mode = 0, range = PF_DEFAULT_RANGE)
      if target.class == LET::Point; @tx = target.x; @ty = target.y; else
        if target < 0; tgt = $game_player.followers[target*-1-1]; else
          tgt = target > 0 ? $game_map.events[target] : $game_player
        end
        @tx = tgt.x; @ty = tgt.y
      end
      tgt_p = Point.new(@tx,@ty)
      char_p = Point.new(@char.x,@char.y)
      rt_metr = Metrics.new(tgt_p,char_p)
      return if rt_metr.tile_distance <= distance 
      return if rt_metr.distance_x.abs > range || rt_metr.distance_y.abs > range
      return unless map_pf_matrix(range+1)
      route = []
      check_step = @step-1
      tx = @tx; ty = @ty
      for i in 1...@step
        dir = [] # vetor de direções para cada passo
        dir << 3 if @pfmap[tx-1,ty] == check_step # direita
        dir << 2 if @pfmap[tx+1,ty] == check_step # esquerda
        dir << 1 if @pfmap[tx,ty-1] == check_step # baixo
        dir << 4 if @pfmap[tx,ty+1] == check_step # cima
        dir = dir[rand(dir.size)]
        case dir
        when 1; ty -= 1
        when 2; tx += 1
        when 3; tx -= 1
        when 4; ty += 1
        end
        route << dir
        check_step -= 1
      end
      route.reverse!
      distance.times do route.pop; end
      case mode
      when 0 # "ir para"
        move_on_route(route) 
      when 1 # "ir para sem esperar"
        set_route(route, false)
        move_on_route()
      when 2 # "seguir"
        set_route(route, false, true, 1)
        move_on_route()
      end
    end
    #--------------------------------------------------------------------------
    # * Mapeia a matriz do pathfind
    # - método utilizado pelo find_path()
    #--------------------------------------------------------------------------    
    def map_pf_matrix(range)
      @pfmap = Table.new($game_map.width, $game_map.height)
      rend = -2 # indicador de fim de rota
      ch = @char.class == Game_Follower ? $game_player : @char #p/ passabilidade
      @pfmap[@char.x,@char.y] = 1
      @pfmap[@tx,@ty] = rend
      cur_count = 1 # apenas 1 flag de passo 0
      # Limitação de escopo de varredura da matriz:
      x_min= @char.x-range > 0 ? @char.x - range : 0
      x_max= @char.x+range < $game_map.width ? @char.x+range : $game_map.width
      y_min= @char.y-range > 0 ? @char.y - range : 0
      y_max= @char.y+range < $game_map.height ? @char.y+range : $game_map.height
      # Encontrar o caminho
      for @step in 2..range
        last_count = cur_count
        cur_count = 0
        while last_count > 0
          for x in x_min...x_max
            for y in y_min...y_max
              if @pfmap[x,y] == @step-1 # Encontrou passo anterior
                ad=[@pfmap[x-1,y],@pfmap[x+1,y],@pfmap[x,y-1],@pfmap[x,y+1]]
                return true if ad.include?(rend)
                if ch.passable?(x,y,4) && ad[0] == 0 # esquerda
                  @pfmap[x-1,y] = @step; cur_count+=1
                end
                if ch.passable?(x,y,6) && ad[1] == 0 # direita
                  @pfmap[x+1,y] = @step; cur_count+=1
                end
                if ch.passable?(x,y,8) && ad[2] == 0 # acima
                  @pfmap[x,y-1] = @step; cur_count+=1
                end
                if ch.passable?(x,y,2) && ad[3] == 0 # abaixo
                  @pfmap[x,y+1] = @step; cur_count+=1
                end
                last_count-=1
              end
              break if last_count == 0
            end
            break if last_count == 0
          end
        end # end while
      end # end of range
      return false
    end
  end
  #----------------------------------------------------------------------------#
  # END LET::PathFinder
  #============================================================================#
end
#------------------------------------------------------------------------------#
# END Module LET
#==============================================================================#
