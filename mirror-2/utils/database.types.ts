export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          operationName?: string
          query?: string
          variables?: Json
          extensions?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      assets: {
        Row: {
          created_at: string
          creator_user_id: string
          description: string | null
          file_url: string
          id: string
          name: string
          owner_user_id: string
          thumbnail_url: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          creator_user_id: string
          description?: string | null
          file_url: string
          id?: string
          name: string
          owner_user_id: string
          thumbnail_url: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          creator_user_id?: string
          description?: string | null
          file_url?: string
          id?: string
          name?: string
          owner_user_id?: string
          thumbnail_url?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "assets_creator_user_id_fkey"
            columns: ["creator_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assets_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      components: {
        Row: {
          attributes: Json | null
          component_key: Database["public"]["Enums"]["component_key"]
          created_at: string
          entity_id: string
          id: string
          updated_at: string
        }
        Insert: {
          attributes?: Json | null
          component_key: Database["public"]["Enums"]["component_key"]
          created_at?: string
          entity_id: string
          id?: string
          updated_at?: string
        }
        Update: {
          attributes?: Json | null
          component_key?: Database["public"]["Enums"]["component_key"]
          created_at?: string
          entity_id?: string
          id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "components_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: false
            referencedRelation: "entities"
            referencedColumns: ["id"]
          },
        ]
      }
      entities: {
        Row: {
          created_at: string
          enabled: boolean
          id: string
          name: string
          parent_id: string | null
          position: number[]
          rotation: number[]
          scale: number[]
          scene_id: string
          tags: string[] | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          enabled?: boolean
          id?: string
          name: string
          parent_id?: string | null
          position?: number[]
          rotation?: number[]
          scale?: number[]
          scene_id: string
          tags?: string[] | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          enabled?: boolean
          id?: string
          name?: string
          parent_id?: string | null
          position?: number[]
          rotation?: number[]
          scale?: number[]
          scene_id?: string
          tags?: string[] | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "entities_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "entities_scene_id_fkey"
            columns: ["scene_id"]
            isOneToOne: false
            referencedRelation: "scenes"
            referencedColumns: ["id"]
          },
        ]
      }
      scenes: {
        Row: {
          created_at: string
          id: string
          name: string
          space_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          space_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          space_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "scenes_space_id_fkey"
            columns: ["space_id"]
            isOneToOne: false
            referencedRelation: "spaces"
            referencedColumns: ["id"]
          },
        ]
      }
      space_user_collaborators: {
        Row: {
          created_at: string
          id: string
          space_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          space_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          space_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "space_user_collaborators_space_id_fkey"
            columns: ["space_id"]
            isOneToOne: false
            referencedRelation: "spaces"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "space_user_collaborators_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      space_versions: {
        Row: {
          created_at: string
          id: string
          name: string
          space_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          space_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          space_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "space_versions_space_id_fkey"
            columns: ["space_id"]
            isOneToOne: false
            referencedRelation: "spaces"
            referencedColumns: ["id"]
          },
        ]
      }
      spaces: {
        Row: {
          created_at: string
          creator_user_id: string
          description: string | null
          id: string
          name: string
          owner_user_id: string
          public_page_image_urls: string[] | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          creator_user_id: string
          description?: string | null
          id?: string
          name: string
          owner_user_id: string
          public_page_image_urls?: string[] | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          creator_user_id?: string
          description?: string | null
          id?: string
          name?: string
          owner_user_id?: string
          public_page_image_urls?: string[] | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "spaces_creator_user_id_fkey"
            columns: ["creator_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spaces_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          avatar_type: Database["public"]["Enums"]["avatar_type"] | null
          created_at: string
          display_name: string
          id: string
          public_bio: string | null
          ready_player_me_url_glb: string | null
          updated_at: string
        }
        Insert: {
          avatar_type?: Database["public"]["Enums"]["avatar_type"] | null
          created_at?: string
          display_name: string
          id?: string
          public_bio?: string | null
          ready_player_me_url_glb?: string | null
          updated_at?: string
        }
        Update: {
          avatar_type?: Database["public"]["Enums"]["avatar_type"] | null
          created_at?: string
          display_name?: string
          id?: string
          public_bio?: string | null
          ready_player_me_url_glb?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_user: {
        Args: {
          email: string
          password: string
        }
        Returns: string
      }
      search_assets_by_name_prefix: {
        Args: {
          prefix: string
        }
        Returns: {
          created_at: string
          creator_user_id: string
          description: string | null
          file_url: string
          id: string
          name: string
          owner_user_id: string
          thumbnail_url: string
          updated_at: string
        }[]
      }
      search_spaces_by_name_prefix: {
        Args: {
          prefix: string
        }
        Returns: {
          created_at: string
          creator_user_id: string
          description: string | null
          id: string
          name: string
          owner_user_id: string
          public_page_image_urls: string[] | null
          updated_at: string
        }[]
      }
    }
    Enums: {
      avatar_type: "ready_player_me"
      component_key:
        | "script"
        | "render"
        | "collision"
        | "rigidbody"
        | "camera"
        | "light"
        | "anim"
        | "sprite"
        | "screen"
        | "element"
        | "button"
        | "particlesystem"
        | "gsplat"
        | "audiolistener"
        | "sound"
        | "scrollbar"
        | "scrollview"
        | "layoutgroup"
        | "layoutchild"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type PublicSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never

