#==============================================================================#
# Lehanius Eventer Tools - Ferramentas para Eventers
#------------------------------------------------------------------------------#
# Autor: Lehanius
#
# Versão: VXA 1.2 BR
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
#   Este script visa auxiliar a programação de eventos, fornecendo ferramentas
# para simplificá-la, por meio de comandos mais diretos para algumas das funções
# mais utilizadas por eventers. Ele também inclui algumas funções que não estão 
# presentes nas opções de eventos.
#   Alguns exemplos são: cálculo de distância entre pontos ou eventos, 
# verificação de região de mapa, comandos de movimento que podem ser usados 
# para seguidores do grupo, entre outros.
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

#==============================================================================#
# Module LET
#------------------------------------------------------------------------------#
module LET
  #============================================================================#
  # LET::Point 
  #----------------------------------------------------------------------------#
  # - ponto que pode ser usado em outras classes, como a LET::Metrics
  # - Para criar um objeto LET::Point, use o comando de script:
  #   point = LET::Point.new(<x>,<y>)
  #----------------------------------------------------------------------------#
  class Point
    attr_accessor :x
    attr_accessor :y
    def initialize(x,y)
      @x = x
      @y = y
    end
  end
  #----------------------------------------------------------------------------#
  # END LET::Point
  #============================================================================#
  #============================================================================#
  # LET::Metrics 
  #----------------------------------------------------------------------------#
  # - executa métodos de medidas e verificações de posição
  # - para criar um objeto LET::Metrics, use o comando de script:
  #   "m = LET:Metrics.new(<alvo>, <observador>)
  #    m.<método>"
  #     <alvo> e <observador> podem ser inteiros ou LET::Point; a escolha desses
  #     parâmetros vai depender do método que será usado; quando inteiros e
  #     <id_personagem>, alvo e observador seguirão esta lógica:
  #       negativo: seguidor  (-1 é o primeiro seguidor, -2 o segundo, etc)
  #       zero:     jogador
  #       positivo: evento    (id do evento)
  # - ver descrição mais detalhada da inicialização em cada método
  #----------------------------------------------------------------------------#
  class Metrics
    #--------------------------------------------------------------------------
    # * Inicializa alvo e observador
    #--------------------------------------------------------------------------
    def initialize(tgt_id, obs_id=0)
      # Target
      if tgt_id.class != LET::Point
        @tgt_id = tgt_id
        if tgt_id < 0; @tgt = $game_player.followers[tgt_id*-1-1]; else
          @tgt = tgt_id > 0 ? $game_map.events[tgt_id] : $game_player; end
        else; @tgt = tgt_id; end
      # Observer
      if obs_id.class != LET::Point
        @obs_id = obs_id      
        if obs_id < 0; @obs = $game_player.followers[obs_id*-1-1]; else
        @obs = obs_id > 0 ? $game_map.events[obs_id] : $game_player; end
      else; @obs = obs_id; end
    end
    #--------------------------------------------------------------------------
    # * Na região? 
    # - LET::Metrics.new(<id_região>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def on_region?
      return $game_map.region_id(@obs.x, @obs.y) == @tgt_id
    end
    #--------------------------------------------------------------------------
    # * Tocou? - para o jogador #nota pessoal: extrair para subclasse
    # - LET::Metrics.new(<id_personagem ou ponto>,<jogador(0)>)
    #--------------------------------------------------------------------------
    def touched?
      return Input.trigger?(:C) && touchable?
    end
    #--------------------------------------------------------------------------
    # * Tocável? - para characters #nota pessoal: extrair para subclasse
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem>)
    #--------------------------------------------------------------------------
    def touchable?
      if adjacent_four? && !@obs.transparent
        return true if relative_pos[0] == @obs.direction
      end
      return false
    end
    #--------------------------------------------------------------------------
    # * Posição do alvo em relação ao observador
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def relative_pos
      rel_pos = []
      rel_pos << 4 if distance_x < 0 #esquerda
      rel_pos << 6 if distance_x > 0 #direita
      rel_pos << 8 if distance_y < 0 #acima
      rel_pos << 2 if distance_y > 0 #abaixo
      rel_pos = [0] if rel_pos.empty?
      return rel_pos
    end
    #--------------------------------------------------------------------------
    # * Possuem adjacência em um dos lados? (sem ser diagonal)
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def adjacent_four?
      return tile_distance == 1
    end
    #--------------------------------------------------------------------------
    # * Distância horizontal (com sinal de sentido)
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def distance_x
      return @tgt.x - @obs.x
    end
    #--------------------------------------------------------------------------
    # * Distância vertical (com sinal de sentido)
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def distance_y
      return @tgt.y - @obs.y
    end
    #--------------------------------------------------------------------------
    # * Distância tile a tile
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def tile_distance
      return distance_x.abs + distance_y.abs
    end
    #--------------------------------------------------------------------------
    # * Distância Euclidiana
    # - LET::Metrics.new(<id_personagem ou ponto>,<id_personagem ou ponto>)
    #--------------------------------------------------------------------------
    def eucl_distance
      return Math::sqrt(distance_y.abs2+distance_x.abs2)
    end
  end
  #----------------------------------------------------------------------------#
  # END LET::Metrics
  #============================================================================#
  #============================================================================#
  # LET::Character - operações de personagem
  #----------------------------------------------------------------------------#
  # - Para inicializar um objeto LET::Character, use o comando de script:
  #   c = LET::Character.new(<id>), onde <id> pode ser negativa, representando
  #   a ordem de um seguidor no grupo (-1 é o primeiro); zero, para o jogador; e
  #   positivo para ids de eventos
  # - Após inicializado, para usar um método basta fazer c.<método>
  #----------------------------------------------------------------------------#
  class Character
    #--------------------------------------------------------------------------
    # * Inicializa o personagem
    # - id < 0: seguidor
    #   id = 0: jogador
    #   id > 0: evento
    #--------------------------------------------------------------------------
    def initialize(id)
      if id < 0; @char = $game_player.followers[id*-1-1]; else
        @char = id > 0 ? $game_map.events[id] : $game_player; end
    end
    #--------------------------------------------------------------------------
    # * Especifica uma rota para o personagem
    # - vetor com valores 1,2,3,4, para andar nas 4 direções
    # - para outros comandos, que não exijam parâmetros, verifique a classe
    #   Game_Character da linha 12 à 57
    # route: uma array contendo os códigos dos comandos da Game_Character
    # wait: esperar
    # skippable?: ignorar se impossível
    # max_steps: número máximo de passos da rota a serem executados
    #--------------------------------------------------------------------------
    def set_route(route, wait = true, skippable = false, max_steps = nil)
      @move_route = RPG::MoveRoute.new
      @move_route.wait = wait
      @move_route.skippable = skippable
      @move_route.repeat = false
      max_steps = route.size if max_steps == nil || max_steps > route.size
      @move_route.list = []
      for i in 0...max_steps
        @move_route.list[i] = RPG::MoveCommand.new(route[i])
      end
      @move_route.list << RPG::MoveCommand.new() # fim de rota
    end
    #--------------------------------------------------------------------------
    # * Move o personagem na rota especificada
    # - Parâmetro deve ser uma array de inteiros dentre os comandos da 
    # Game_Character ou nil(depois de um set_route)
    #--------------------------------------------------------------------------
    def move_on_route (route = nil)
      set_route(route) if route
      @char.force_move_route(@move_route)
      Fiber.yield while @char.move_route_forcing if @move_route.wait
    end
    #--------------------------------------------------------------------------
    # * Zera a opacidade do personagem
    # rate: taxa de diminuição da opacidade por frame
    #--------------------------------------------------------------------------
    def fade_out(rate = 3)    
      fade(-rate.abs)
    end
    #--------------------------------------------------------------------------
    # * Maximiza a opacidade do personagem
    # rate: taxa de aumento da opacidade por frame
    #--------------------------------------------------------------------------
    def fade_in(rate = 3)
      fade(rate.abs)
    end
    #--------------------------------------------------------------------------
    # * Muda a opacidade do personagem
    # rate: taxa de mudança da opacidade por frame
    #--------------------------------------------------------------------------
    def fade(rate)
      set_route([], false)
      new_opc = @char.opacity
      while true
        new_opc += rate
        new_opc = 0 if new_opc < 0
        new_opc = 255 if new_opc > 255
        @move_route.list.unshift(RPG::MoveCommand.new(42,[new_opc]))
        @move_route.list.unshift(RPG::MoveCommand.new(15,[1]))
        break if new_opc == 0
        break if new_opc == 255
      end
      @move_route.list.reverse!
      @move_route.list << @move_route.list.shift
      move_on_route()
    end
  end
  #----------------------------------------------------------------------------#
  # END LET::Character
  #============================================================================#
end
#------------------------------------------------------------------------------#
# END Module LET
#==============================================================================#
#==============================================================================#
# Game_Player
#------------------------------------------------------------------------------#
# - Foi adicionado o attr_accessor :followers_follow, para desativar ou ativar
#   os seguidores seguindo o herói
# - Para desativar, use o comando de script: 
#     $game_player.followers.follow = false
# - Para ativar, use o comando de script: 
#     $game_player.followers.follow = true
#------------------------------------------------------------------------------#
class Game_Player < Game_Character
  attr_accessor :followers_follow # para seguir ou parar de seguir
  #--------------------------------------------------------------------------
  # * Inicialização do objeto
  #--------------------------------------------------------------------------
  alias let_initialize initialize
  def initialize
    let_initialize
    @followers_follow = true
  end
  #--------------------------------------------------------------------------
  # * Movimento em linha reta em
  #     d       : direção （2,4,6,8）
  #     turn_ok : permissão para mudar de direção
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true)
    @followers.move if passable?(@x, @y, d) && @followers_follow
    super
  end
  #--------------------------------------------------------------------------
  # * Movimento na diagonal
  #     horz : direção horizontal （4 or 6）
  #     vert : direção vertical   (2 or 8）
  #--------------------------------------------------------------------------
  def move_diagonal(horz, vert)
    @followers.move if diagonal_passable?(@x, @y, horz, vert)  && @followers_follow
    super
  end
end
#------------------------------------------------------------------------------#
# END Game_Player
#==============================================================================#
