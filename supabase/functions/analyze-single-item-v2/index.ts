import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')

serve(async (req) => {
  try {
    const { base64Image, model = "gpt-4o", maxTokens = 500, temperature = 0.3 } = await req.json()

    if (!base64Image) {
      return new Response(
        JSON.stringify({ error: "Missing base64Image parameter" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    const enhancedPrompt = `You are an expert at analyzing product images for online marketplace listings (eBay, Poshmark, Facebook Marketplace, etc.).

Given this image, extract the following information:

1. ITEM: The specific name/title of the item (be descriptive but concise, max 80 chars)

2. CATEGORY: The most specific category path (e.g., "Electronics > Cell Phones & Accessories > Headphones" or "Clothing, Shoes & Accessories > Men's Shoes > Athletic Shoes")

3. CONDITION: One of: New, Like New, Good, Fair, Poor
   - Include specific condition details (scratches, wear patterns, functionality issues)

4. DESCRIPTION: A detailed 2-3 sentence description highlighting:
   - Key features and specifications
   - Notable condition details
   - What makes this item valuable or unique

5. VALUE: Estimated resale value range in format "$XX - $YY" based on condition and market demand

6. ATTRIBUTES: Extract category-specific attributes as key-value pairs. Based on the category, include ONLY relevant attributes:

   For FOOTWEAR: Brand, US Shoe Size, Width, Color, Style, Material
   For ELECTRONICS: Brand, Model, Storage Capacity, Color, Connectivity, Operating System
   For CLOTHING: Brand, Size, Size Type, Color, Material, Style, Fit
   For BOOKS: Title, Author, Format, ISBN, Publisher, Publication Year, Language
   For AUDIO EQUIPMENT: Brand, Model, Type, Connectivity, Color, Features
   For SPORTS EQUIPMENT: Brand, Sport, Size, Material, Color
   For HOME GOODS: Brand, Material, Dimensions, Color, Style, Room Type
   For OTHER CATEGORIES: Extract the most relevant identifying attributes

   **IMPORTANT**:
   - Use "Not Specified" or "Unknown" ONLY if truly not visible in the image
   - Extract as many attributes as possible from visible details
   - Be specific (e.g., "Nike" not "Unknown", "Size 10.5" not "Not Specified")
   - Format as JSON object: {"Brand": "Nike", "US Shoe Size": "10.5", "Color": "Black/White"}

Format your response EXACTLY as follows (no extra text):

ITEM: [item name]
CATEGORY: [category path]
CONDITION: [condition]
DESCRIPTION: [description]
VALUE: [value range]
ATTRIBUTES: {"key1": "value1", "key2": "value2", ...}`

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        temperature,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: enhancedPrompt
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`
                }
              }
            ]
          }
        ]
      })
    })

    if (!response.ok) {
      const errorData = await response.json()
      console.error("OpenAI API error:", errorData)
      return new Response(
        JSON.stringify({ error: "OpenAI API request failed", details: errorData }),
        { status: response.status, headers: { "Content-Type": "application/json" } }
      )
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

    if (!content) {
      return new Response(
        JSON.stringify({ error: "No content in OpenAI response" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    return new Response(
      JSON.stringify({ content }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    )

  } catch (error) {
    console.error("Edge function error:", error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
