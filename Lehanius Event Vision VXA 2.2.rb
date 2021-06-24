#==============================================================================#
# Lehanius Event Vision - Visão para Eventos
#------------------------------------------------------------------------------#
# Autor: Lehanius
#
# Versão: VXA 2.2 BR
# Data: d/m 03/11/2013
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
#   Este script permite que eventos do mapa tenham visão sobre outros eventos 
# ou sobre o herói. A área de obstrução da visão é verificada de forma 
# relativamente realista, respeitando o ângulo de observação.   
#==============================================================================#
#
#==============================================================================#
# Histórico das versões
#------------------------------------------------------------------------------#
# - vxa 2.1 11/01/2012
# - vxa 2.2 03/11/2013  <> acelera processamento para alvos distantes
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
                               
  Para utilizar este sistema, em cada evento ao qual você quiser atribuir visão,
devem ser colocados 2 comentários.
  - no primeiro comentário, a primeira linha deve ser, obrigatoriamente, 
VISION_if (ou PROX_if)
  - a segunda linha do primeiro comentário deve conter, separados por vírgula, 
o alcance da visão e o alvo do observador.
  - o segundo comentário geralmente virá depois de outras linhas de código e
deve conter, obrigatoriamente, VISION_endif (ou PROX_endif)
 
    Exemplo:
        Opções de Variável:[0001]=10          |
      * Comentário:VISION_if                  | início da condição
                   6,0                        | (range = 6, alvo = herói)
        Reproduzir SE:'Dog',80,100            |
        Operação de Switch Local: A=ON        |
      * Comentário:VISION_endif               | fim da condição
        Mudar Dinheiro:+1                     |
   
    Esse código nos eventos funciona como uma condição: o código que está entre
  o primeiro comentário e o segundo só é executado se o evento vir seu alvo.
 
    No exemplo acima, só será tocado o SE do cachorro e só será alterada a
  switch local A se VISION_if(6, 0) retornar verdadeiro, ou seja, o alvo estiver
  no campo de visão do evento.
  
    O sistema de percepção de proximidade funciona de forma similar ao de visão,
  mas ele usa PROX_if e PROX_endif como limites da condição.
                               
 
  Explicação dos parâmetros:
 
  A segunda linha do primeiro comentário fornece os parâmetros para a visão. 
O primeiro é o range, o alcance da visão. Esse alcance é determinado pela 
distância euclidiana entre os tiles e o evento observador.
  O segundo parâmetro (2º linha do primeiro comentário, após a vírgula), é o 
evento alvo da visão. Seu conteúdo deve ser a ID do evento alvo ou, caso queira 
que o evento procure o herói, esse segundo parâmetro deve ser omitido (ou 0).


  Terrain Tags:
  
  Para tornar transparentes tiles não-passáveis (como tiles de água), basta 
inserir as tags de terrenos que devem ser transparentes no vetor TRANS_TAGS, nas 
configurações, e ajustar as tags no database.
  

  Modo teste:
 
  O modo teste é apenas um meio para ajudar a visualisar o campo de visão do seu
evento, para que você possa ajustar seus parâmetros de forma conveniente.
                               
=end

#==============================================================================#
# + Config - Edite estes valores para configurar o sistema
#------------------------------------------------------------------------------#
module LEVS
ADJUST = 0.75   # ajuste do escopo direcional de oclusão - não modifique
TRANS_TAGS = [1,2] # valores de tag que devam indicar transparência de tile
#------------------------------------TEST MODE---------------------------------#
TEST_MODE = true
DEF_V_COLOR = Color.new( 90, 30, 90, 70)  # cor do campo de visão no test mode
DEF_P_COLOR = Color.new(120,120, 30, 70)  # cor do campo de proximidade
end
#------------------------------------------------------------------------------#
# END Config
#==============================================================================#
#==============================================================================#
# Game Interpreter
#------------------------------------------------------------------------------#
class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Comentários: verifica a condição de visão
  #--------------------------------------------------------------------------
  alias levs_command_108 command_108
  def command_108
    levs_command_108
    if ["VISION_if", "PROX_if"].include?(@comments[0])
      range_target = @comments[1]
      range_target += ",0" if !range_target.include?(",")
      observe = Event_Vision.new
      levs_method = @comments[0].chomp("_if").downcase+"("
      levs_end = @comments[0].gsub("if","endif")
      if !eval("observe."+levs_method+@event_id.to_s+","+range_target+")")
        while !(next_event_code == 108 and @list[@index+1].parameters[0] == levs_end)
          @index += 1
        end
        @index+=1
      end
    end
  end
end
#------------------------------------------------------------------------------#
# END Game_Interpreter
#==============================================================================#
#==============================================================================#
# Event Vision
#------------------------------------------------------------------------------#
class Event_Vision
  #--------------------------------------------------------------------------
  # * Ajusta o escopo de visão do evento
  #--------------------------------------------------------------------------
  def direction_adjust(dir, a, b)
    case dir
    when 2 #baixo
      if b>=0 and b.abs>=a.abs
        return true
      end
    when 4 #esquerda
      if a<=0 and b.abs<=a.abs
        return true
      end
    when 6 #direita
      if a>=0 and b.abs<=a.abs
        return true
      end
    when 8 #cima
      if b<=0 and b.abs>=a.abs
        return true
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Verifica se um tile foi determinado como transparente
  #--------------------------------------------------------------------------  
  def transparent?(x,y)
    i = 1
    adj = 0 #ajuste do tamanho, considerando os eventos nil
    while(i<=$game_map.events.length+adj)
      if $game_map.events[i] != nil
        # The following condition fixes issues caused by erased events
        unless $game_map.events[i].empty?
          event_com1 = $game_map.events[i].list[0] 
          if event_com1.code == 108
            # Eventos individuais indicadores de transparência
            if event_com1.parameters[0] == "TRANSPARENT"
              if $game_map.events[i].x == x and $game_map.events[i].y == y
                return true
              end
            end
            # Evento indicador de coordenadas de transparência
            if event_com1.parameters[0] == "TRANS LIST"
              for j in 0...$game_map.events[i].list.length-1
                if $game_map.events[i].list[j].parameters[0] == x.to_s+","+y.to_s
                  return true
                end
              end
            end
          end
        end
      else 
        adj += 1
      end
      i += 1
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Verifica se há obstrução da visão
  #--------------------------------------------------------------------------
  def hide_check(dir, visible, i, j, c1, c2, dx, dy)
    case dir
    when 2 #baixo
      if visible[j][1] >= visible[i][1] and dx < c1*dy and dx > c2*dy
        return true
      end
    when 4 #esquerda
      c1 = 1/c1
      c2 = 1/c2
      if visible[j][0] <= visible[i][0] and dy < c1*dx and dy > c2*dx
        return true
      end
    when 6 #direita
      c1 = 1/c1
      c2 = 1/c2
      if visible[j][0] >= visible[i][0] and dy < c1*dx and dy > c2*dx
        return true
      end
    when 8 #cima
      if visible[j][1] <= visible[i][1] and dx < c1*dy and dx > c2*dy
        return true
      end
    end
    return false   
  end
  #--------------------------------------------------------------------------
  # * Verificação da visão do observador sobre seu objetivo
  #--------------------------------------------------------------------------
  def vision(id, range, target)
    @id = id
    @range = range
    visible = []
    invisible=[]
    # Determina o observador
    obs = $game_map.events[id]
    # Determina o alvo do observador
    if target <= 0
      target = $game_player
    else
      target = $game_map.events[target]
    end
    #Encerra antecipadamente a verificação de visão se o alvo estiver fora do alcance do observador
    if (target.x-obs.x)*(target.x-obs.x)+(target.y-obs.y)*(target.y-obs.y) > range*range
      return false
    end
    #Determina o alcance de visão do observador, independentemente dos obstáculos
    for x in obs.x-range..obs.x+range
      for y in obs.y-range..obs.y+range
        a = x-obs.x
        b = y-obs.y
        if a*a+b*b<=range*range and direction_adjust(obs.direction, a, b)
          if x>=0 and y>=0 and x<$game_map.width and y<$game_map.height
            visible<<[x, y]
          end
        end
      end
    end
    # Aplica o ajuste horizontal ou vertical de oclusão
    if obs.direction == 2 or obs.direction == 8 #baixo ou cima
      adjust_x = LEVS::ADJUST
      adjust_y = 0
    else #esquerda ou direita
      adjust_x = 0
      adjust_y = LEVS::ADJUST
    end
    # Determina os tiles de visão obstruída
    for i in 0...visible.length
      v_x = visible[i][0]
      v_y = visible[i][1]
      if !$game_map.check_passage(v_x, v_y, 0x0f) and !transparent?(v_x ,v_y) and !LEVS::TRANS_TAGS.include?($game_map.terrain_tag(v_x,v_y))
        #trata para que o alvo procurado não seja identificado como obstáculo
        if !(v_x == target.x and v_y == target.y)
          c1 = (v_x+adjust_x - obs.x) / (v_y+adjust_y - obs.y)
          c2 = (v_x-adjust_x - obs.x) / (v_y-adjust_y - obs.y)
          for j in 0...visible.length
            dx = visible[j][0]-obs.x
            dy = visible[j][1]-obs.y
            if hide_check(obs.direction,visible,i,j,c1,c2,dx,dy)
              invisible<<visible[j]
            end
          end
        end
      end
    end
    # Tiles observados
    @visible_tiles = visible - invisible
    # Resultado da observação
    @observed = @visible_tiles.include?([target.x, target.y])
    # TEST MODE
    test_mode if LEVS::TEST_MODE
    # Retorna o resultado da verificação de visão
    return @observed
  end
  #--------------------------------------------------------------------------
  # * Verificação da percepção de proximidade
  #--------------------------------------------------------------------------
  def prox(id, range, target)
    @id = id
    @range = range
    @prox_area = []
    # Determina o observador
    obs = $game_map.events[id]
    # Determina o alvo do observador
    if target <= 0
      target = $game_player
    else
      target = $game_map.events[target]
    end
    #Determina o alcance de visão do observador, independentemente dos obstáculos
    for x in obs.x-range..obs.x+range
      for y in obs.y-range..obs.y+range
        a = x-obs.x
        b = y-obs.y
        if a*a+b*b<=range*range
          if x>=0 and y>=0 and x<$game_map.width and y<$game_map.height
            @prox_area<<[x, y]
          end
        end
      end
    end
    # Resultado da percepção de proximidade
    @prox_close = @prox_area.include?([target.x, target.y])
    # TEST MODE
    test_mode if LEVS::TEST_MODE
    return @prox_close
  end
  #--------------------------------------------------------------------------
  # * TEST MODE
  #--------------------------------------------------------------------------  
  def test_mode
    show_vision #mostra a área de visão
    print "Alvo detectado" if @observed || @prox_close
  end
  #--------------------------------------------------------------------------
  # * Mostra a área de visão do evento - Test Mode
  #--------------------------------------------------------------------------
  def show_vision
    wdt = 64*(@range+1) #bitmap width
    hgt = 64*(@range+1) #bitmap height
    id = @id
    id += $game_map.events.size if @prox_area
    $game_temp.levs_sprites[id] = Sprite.new if !$game_temp.levs_sprites[id]
    $game_temp.levs_bitmaps[id] = Bitmap.new(wdt,hgt) if !$game_temp.levs_bitmaps[id]
    rect = Rect.new(0, 0, 32, 32)
    vision_color = LEVS::DEF_V_COLOR
    prox_color = LEVS::DEF_P_COLOR
    $game_temp.levs_bitmaps[id].clear
    if @visible_tiles
      for i in 0...@visible_tiles.length
        rect_x = @visible_tiles[i][0]-$game_map.events[@id].x+wdt/64
        rect_y = @visible_tiles[i][1]-$game_map.events[@id].y+hgt/64
        rect = Rect.new(rect_x*32,rect_y*32,32,32)
        $game_temp.levs_bitmaps[id].fill_rect(rect, vision_color)
      end
    end
    if @prox_area
      for i in 0...@prox_area.length
        rect_x = @prox_area[i][0]-$game_map.events[@id].x+wdt/64
        rect_y = @prox_area[i][1]-$game_map.events[@id].y+hgt/64
        rect = Rect.new(rect_x*32,rect_y*32,32,32)
        $game_temp.levs_bitmaps[id].fill_rect(rect, prox_color)
      end
    end
    $game_temp.levs_bitmaps[id].clear if @observed || @prox_close
    $game_temp.levs_sprites[id].ox = wdt/2
    $game_temp.levs_sprites[id].oy = hgt/2
    adj_x = 0
    adj_y = 0
    adj_x = 8-$game_player.x if $game_player.x > 8
    adj_y = 6-$game_player.y if $game_player.y > 6
    adj_x += 9-($game_map.width-$game_player.x) if $game_map.width-$game_player.x<=8
    adj_y += 7-($game_map.height-$game_player.y) if $game_map.height-$game_player.y<=6
    $game_temp.levs_sprites[id].x = ($game_map.events[@id].x+adj_x)*32
    $game_temp.levs_sprites[id].y = ($game_map.events[@id].y+adj_y)*32
    $game_temp.levs_sprites[id].bitmap = $game_temp.levs_bitmaps[id]
  end
end
#------------------------------------------------------------------------------#
# END Event Vision
#==============================================================================#
#==============================================================================#
# Game_Temp - para os sprites e bitmaps do modo teste
#------------------------------------------------------------------------------#
class Game_Temp
  attr_accessor :levs_sprites
  attr_accessor :levs_bitmaps
  alias levs_initialize initialize
  def initialize
    levs_initialize
    @levs_bitmaps = []
    @levs_sprites = []
  end
end
#------------------------------------------------------------------------------#
# END Game_Temp
#==============================================================================#
